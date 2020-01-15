### build image
docker build -t imgname .

### run container
docker run --name container_name imgname --bind 127.0.0.1

### run container with port
docker run -d --name container_name -p 8888:8888 image_name

### start/stop/restart the container
docker restart container_name

### remove container
docker rm containerid

### remove image from docker
docker rmi imageName

### format of Dockerfile
FROM anapsix/alpine-java  
MAINTAINER bhushanp  
COPY badam7-0.0.1-SNAPSHOT.jar /home/badam7-0.0.1-SNAPSHOT.jar  
CMD ["java","-jar","/home/badam7-0.0.1-SNAPSHOT.jar"]  
expose 8888 ### only used for inter-container communication  

 
