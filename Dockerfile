ARG NODE_TAG="14.19.2-alpine3.15"
ARG NPM_VER="8.14.0"

# Install dependencies only when needed
FROM node:${NODE_TAG} AS deps
WORKDIR /usr/src/app
COPY . ./
RUN npm install npm@${NPM_VER} -g
RUN yarn install --frozen-lockfile --production

# Rebuild the source code only when needed
FROM node:${NODE_TAG} AS builder
WORKDIR /usr/src/app
RUN npm install npm@${NPM_VER} -g
COPY tsconfig.json package.json yarn.lock ./
COPY public ./public
COPY src ./src
COPY --from=deps /usr/src/app/node_modules ./node_modules
RUN yarn build

# Production image, copy all the files and run next
FROM node:${NODE_TAG} AS runner
# Set EU Brussels TZ
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime
RUN echo "Europe/Brussels" >  /etc/timezone
RUN date
RUN apk del tzdata
#
WORKDIR /usr/src/app
RUN npm install npm@${NPM_VER} -g
ENV PORT 3000
ENV NODE_ENV=production
COPY --from=builder /usr/src/app .
EXPOSE 3000
CMD ["yarn", "start"]
