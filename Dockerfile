## Build API
FROM arm32v7/node:13-alpine as api

WORKDIR /usr/src/app

COPY ohmyform/ui/ .

RUN yarn install --frozen-lockfile
RUN yarn export
RUN yarn autoclean

## Build APP
FROM arm32v7/node:13-alpine as app
LABEL maintainer="OhMyForm <admin@ohmyform.com>"

WORKDIR /usr/src/app

RUN apk update && apk add curl bash python make gcc g++ mongodb redis && rm -rf /var/cache/apk/*

# install node-prune (https://github.com/tj/node-prune)
# RUN curl -sf https://gobinaries.com/tj/node-prune | sh


COPY ohmyform/api/ .
COPY --from=api /usr/src/app/out /usr/src/app/public

RUN yarn install --frozen-lockfile
RUN yarn build
RUN yarn autoclean

# remove development dependencies
# RUN npm prune --production

# run node prune
# RUN /usr/local/bin/node-prune

## Glue
RUN touch /usr/src/app/src/schema.gql && chown 9999:9999 /usr/src/app/src/schema.gql

## Production Image.
FROM arm32v7/node:13-alpine

WORKDIR /usr/src/app
COPY --from=app /usr/src/app /usr/src/app
RUN addgroup --gid 9999 ohmyform && adduser -D --uid 9999 -G ohmyform ohmyform
ENV PORT=3000 \
    SECRET_KEY=ChangeMe \
    CREATE_ADMIN=FALSE \
    ADMIN_EMAIL=admin@ohmyform.com \
    ADMIN_USERNAME=root \
    ADMIN_PASSWORD=root

EXPOSE 3000
USER ohmyform
CMD [ "yarn", "start:prod" ]
