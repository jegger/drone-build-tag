FROM alpine:latest
ENV APPLICATION_VERSION 0.0.1

RUN apk add --no-cache jq bash git openssh libxml2 libxml2-utils python

ADD ./build-tags.sh /bin

# CMD [ "build-tags.sh" ]
CMD ["bash"]