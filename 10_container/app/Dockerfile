FROM ubuntu

RUN echo "Building winston-app image"
ENV RUST_BACKTRACE=1
ENV WEB_BIND_ADDRESS=0.0.0.0
ENV WEB_BIND_PORT=8000

COPY web-api /usr/bin

#CMD ["tail", "-f", "/dev/null"]
CMD ["/usr/bin/web-api"]