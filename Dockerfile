FROM anapsix/alpine-java
MAINTAINER bhushanp
COPY target/badam7-0.0.1-SNAPSHOT.jar /home/badam7-0.0.1-SNAPSHOT.jar
CMD ["java","-jar","/home/badam7-0.0.1-SNAPSHOT.jar"]
expose 8888
