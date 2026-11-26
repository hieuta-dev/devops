FROM node:24-alpine

WORKDIR /home/node/app

COPY package*.json ./

RUN npm ci --only=production
EXPOSE 8080
COPY *js .
COPY views views
ENTRYPOINT ["npm", "start"]