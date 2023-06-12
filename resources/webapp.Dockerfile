# Simple & easy dockerfile for a nodejs webapp
FROM node:14-alpine

WORKDIR /app

COPY ./webapp/package*.json ./

RUN npm install

COPY ./webapp .

EXPOSE 4000

CMD ["node", "index.js"]
