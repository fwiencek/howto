# @see https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md

# base
FROM node:14-slim AS base

RUN mkdir /app && chown -R node:node /app
WORKDIR /app

USER node

COPY --chown=node:node package.json yarn.lock ./

RUN yarn install --production --frozen-lockfile && yarn cache clean

# build
FROM base AS build

RUN yarn install --frozen-lockfile

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --chown=node:node tsconfig.json next-env.d.ts next.config.js ./
COPY --chown=node:node scripts ./scripts
COPY --chown=node:node config ./config
COPY --chown=node:node postcss.config.js tailwind.config.js ./
COPY --chown=node:node public ./public
COPY --chown=node:node src ./src
COPY --chown=node:node content ./content

RUN yarn build

# serve
FROM base AS serve

ENV NODE_ENV=production

COPY --from=build --chown=node:node /app/next.config.js ./
COPY --from=build --chown=node:node /app/public ./public
COPY --from=build --chown=node:node /app/.next ./.next

# Ensures folder is owned by node:node when mounted as volume.
RUN mkdir -p /app/.next/cache/images

EXPOSE 3000

CMD ["node", "node_modules/.bin/next", "start"]
