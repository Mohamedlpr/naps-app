FROM node:22-alpine

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --chown=node:node . .
USER node
ENV NODE_ENV=production
EXPOSE 4000
CMD ["node", "server.js"]
