# This Dockerfile installs a compiled binary into an image with no system at all.
# You must either commit your compiled binary into source control (not recommended)
# or build the binary first as part of a CI/CD pipeline.
# Your binary must be statically compiled with no dynamic dependencies on system libraries.
# e.g. for Docker:
# CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM scratch

# Since we started from scratch, we'll likely need to add SSL root certificates
ADD /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /usr/local/bin

# Change `app` to whatever your binary is called
Add app .
CMD ["./app"]
