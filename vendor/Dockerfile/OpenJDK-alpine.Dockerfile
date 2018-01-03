FROM openjdk:8-alpine

COPY . /usr/src/myapp
WORKDIR /usr/src/myapp

RUN javac Main.java

CMD ["java", "Main"]
