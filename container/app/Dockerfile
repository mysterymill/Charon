FROM ubuntu

RUN echo "Building winston-app image"
ENV TS_DATABASE_ADDRESS=winston-mariadb:3306
ENV TS_DATABASE_PRINCIPAL=winston
ENV TS_DATABASE_PASSWORD=G3n3ricPwd
ENV RUST_BACKTRACE=1
ENV WEB_BIND_ADDRESS=0.0.0.0
ENV WEB_BIND_PORT=8000

COPY ../../web-api/build/web-api /usr/bin

#CMD ["tail", "-f", "/dev/null"]
CMD ["/usr/bin/web-api"]