FROM golang:1.10.1 as builder

ENV GIT_COMMIT 9ce254d3b4c86bb3d0ecf7d27556c7ea21c08894

RUN apt-get update && apt-get install -y git bash openssl curl ca-certificates \
  && go get -d github.com/square/certstrap \
  && cd ${GOPATH}/src/github.com/square/certstrap \
  && git checkout ${GIT_COMMIT} \
  && ./build \
  && cp bin/certstrap-$(git describe --all | sed -e's/.*\///g')-linux-amd64 /usr/local/bin/certstrap

FROM nginx:1.13

LABEL "com.github.repo"="bpanel-org/bpanel"
LABEL "maintainer"="bcoin"
LABEL "version"="0.0.1"

COPY --from=builder /usr/local/bin/certstrap /usr/local/bin/

# main application scripts
COPY scripts /opt/securityc
# nginx config
COPY config /etc/nginx

CMD ["/opt/securityc/entrypoint.sh"]

