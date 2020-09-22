FROM golang:1.15-alpine AS builder

# We'll likely need to add SSL root certificates
RUN apk --no-cache add ca-certificates

WORKDIR /usr/src/app

COPY . .
RUN go-wrapper download
RUN CGO_ENABLED=0 GOOS=linux go build -v -a -installsuffix cgo -o app .

FROM scratch

# Since we started from scratch, we'll copy the SSL root certificates from the builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /usr/local/bin

COPY --from=builder /usr/src/app/app .
CMD ["./app"]
