## Build API
FROM node:14-alpine as api

WORKDIR /root/ohmyform/app

COPY ohmyform/ui/ .

RUN yarn install --frozen-lockfile
RUN yarn export

## Build APP
FROM node:14-alpine as app
LABEL maintainer="OhMyForm <admin@ohmyform.com>"

WORKDIR /root/ohmyform/app

RUN apk update && apk add curl bash && rm -rf /var/cache/apk/*

# install node-prune (https://github.com/tj/node-prune)
RUN curl -sf https://gobinaries.com/tj/node-prune | sh


COPY ohmyform/api/ .
COPY --from=api /root/ohmyform/app/out /root/ohmyform/app/public

RUN yarn install --frozen-lockfile
RUN yarn build

# remove development dependencies
RUN npm prune --production

# run node prune
RUN /usr/local/bin/node-prune

## Glue
RUN touch /root/ohmyform/app/src/schema.gql && chown 9999:9999 /root/ohmyform/app/src/schema.gql

## Production Image.
FROM node:14-alpine

WORKDIR /root/ohmyform/app
COPY --from=app /root/ohmyform/app /root/ohmyform/app
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
