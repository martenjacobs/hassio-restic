ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

COPY run.sh /

RUN chmod a+x /run.sh

RUN apk add --no-cache restic openssh udev

WORKDIR /data

CMD [ "/run.sh" ]
