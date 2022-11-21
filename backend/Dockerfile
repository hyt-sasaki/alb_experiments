FROM node:19-buster-slim

WORKDIR /app

ENV NODE_ENV=production
COPY . .
RUN npm install

CMD ["npm", "start"]
