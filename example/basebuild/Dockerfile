FROM ishaanmalhi/ubuntu-node:base-10

RUN apt-get install make

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "index"]
