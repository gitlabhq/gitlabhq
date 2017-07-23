FROM openjdk:9

COPY . /usr/src/myapp
WORKDIR /usr/src/myapp

RUN javac Main.java

CMD ["java", "Main"]
