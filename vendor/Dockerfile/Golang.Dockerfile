FROM golang:1.8 AS builder

WORKDIR /usr/src/app

COPY . .
RUN go-wrapper download
RUN go build -v

FROM buildpack-deps:jessie

WORKDIR /usr/local/bin

COPY --from=builder /usr/src/app/app .
CMD ["./app"]
