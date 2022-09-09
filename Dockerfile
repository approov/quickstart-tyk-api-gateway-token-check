ARG TAG=4.1

FROM tykio/tyk-gateway:${TAG}

RUN pip3 install PyJWT
