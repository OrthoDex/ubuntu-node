# Production Ready Node.js Docker Base Images

### Status
![Docker](https://github.com/OrthoDex/ubuntu-node/workflows/Docker/badge.svg?branch=master)

## Why:

Other alternatives have the kitchen sink in the image. Not a great trade off between small images and reliability.

This docker image installs what is necessary and leaves the rest upto the developer to install. It's a simple "batteries included" version of production Node.js images.

This image has been built based on our experience in running over 1000s of containers executing Node.js apps.

## Features:

- Docker layer caching for node_modules
- [Tini](https://github.com/krallin/tini) as init process.
- ONBUILD triggers based on convention for simplifying application Dockerfile
- non sudo `node` user

## Contributing:

All PRs and Issues welcome!

## Examples

```
$ docker run ishaanmalhi/ubuntu-node:10 node --version
```

## Using the dockerfile as base image for your Node.js project

1. For general use cases, you should use the full image. This includes build triggers that will copy the code in your home folder, install the npm dependencies and set the user to node.

```
FROM ishaanmalhi/ubuntu-node:10

# Expose app port
EXPOSE 3000

CMD ["node", "index"]
```

2. If you know what native npm module dependencies you need, you should use the base images. They are about 200 MBs smaller than the full images since they don't contain the `build-essential` package, which is needed for generic node images.

```
FROM ishaanmalhi/ubuntu-node:base-10

RUN apt-get install make

COPY package*.json .

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "index"]
```

## Inspiration

https://github.com/mhart/alpine-node
