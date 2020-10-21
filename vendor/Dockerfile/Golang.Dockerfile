FROM golang:1.15 AS builder

WORKDIR /usr/src/app

COPY . .
RUN go-wrapper download
RUN go build -v

FROM buildpack-deps:buster

WORKDIR /usr/local/bin

COPY --from=builder /usr/src/app/app .
CMD ["./app"]
