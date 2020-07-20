FROM rust:1.45 as builder

WORKDIR /usr/src/app

COPY . .
RUN cargo build --release

FROM debian:buster-slim

COPY --from=builder /usr/src/app/target/release/app .

EXPOSE 8080
CMD ["./app"]
