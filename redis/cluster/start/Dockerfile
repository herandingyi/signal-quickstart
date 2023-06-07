#docker build -t test .
FROM alpine/git:2.36.3 AS clone-signal-server
RUN mkdir -p /myapp/signal-server && \
    git clone --branch v7.71.0 https://github.com/signalapp/Signal-Server.git /myapp/signal-server

FROM redis:7.0.4-bullseye
COPY --from=clone-signal-server  /myapp/signal-server/service/src/main/resources/lua /mylua
