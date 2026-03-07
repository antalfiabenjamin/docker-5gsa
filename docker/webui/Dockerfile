FROM node:20-slim

ARG OPEN5GS_VERSION=v2.7.5

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${OPEN5GS_VERSION} https://github.com/open5gs/open5gs.git /opt/open5gs

WORKDIR /opt/open5gs/webui
RUN npm ci

ENV DB_URI=mongodb://fiveg-cn-db/open5gs
ENV HOSTNAME=0.0.0.0
ENV PORT=9999

EXPOSE 9999

CMD ["npm", "run", "dev"]