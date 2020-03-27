### Format of Dockerfile 
```
FROM anapsix/alpine-java 
MAINTAINER bhushanp 
COPY myapp.jar /home/myapp.jar 
CMD ["java","-jar","/home/myapp.jar"] 
expose 8888 ### only used for inter-container communication
```


#### Build image 
	docker build -t imgname . 

#### Run container 
	docker run --name container_name imgname --bind 127.0.0.1 

#### Run container with port 
	docker run -d --name container_name -p 8888:8888 image_name 

#### Run container with autostart flag 
	docker run -d --name container_name -p 8888:8888 --restart unless-stopped image_name 

#### Start/Stop/Restart the container 
	docker restart container_name 

#### List images
	docker images

#### Remove image from docker 
	docker rmi imageName

#### Remove image(forcefully)
	docker rmi -f imagename/imageid

#### List containers
	docker containers list

#### Remove container 
	docker rm containerid 

## Volume 
#### To create a volume
	docker volume create [name of volume]  

#### To verify volume
	docker volume ls  

#### To delete volume
	docker volume prune  

#### Remove a single volume
	docker volume rm [name of volume]  

#### See more details on our created volume and probably most important where it will place the persisted files. 
	docker inspect [name of volume]  

#### To mount volume to app
	docker run -d -p 8000:3000 --name my-container --volume my-volume:/logs chrisnoring/node
	(-v [name of volume]:[directory in the container], for example -v my-volume:/app)  

## Integration with Nexus 
### Add Nexus’s private repo’s ip:port to /etc/docker/daemon.json’s insecure-registries & registry-mirrors fields ex.
	```
	/etc/docker/daemon.json
	{
		"insecure-registries": [
			"192.168.1.10"
		],
		"registry-mirrors": [
			"http://192.168.1.10/nexus/repository/docker-group"
		]
	}
	```

### Push the image to repo
#### First tag the image 
	docker tag {image_id/imagenamge} nexus_ip:nexus_port_of_private_repo/repo_for_img:tag 
	docker tag 2d01ec6570c5/imagename 10.1.3.25:8890/myrepo:latest 

#### Push the image 
	docker push  nexus_ip:nexus_port_of_private_repo/repo_for_img:tag 

#### Pull the image
	docker pull nexus_ip:nexus_port_of_private_repo/repo_for_img:tag 

#### Bring down the container
	docker stop container_name

#### Remove the container
	docker rm container_name

#### Rebuild the image 
	docker build -t imagename

#### Run the container again
	docker run -d --name container_name -p 8888:8888 image_name

## Kubernetes
#### How to install single node cluster(choices - microk8s & minikube, selected - straightforward installation process for Ubuntu)
	sudo snap install microk8s --classic

#### Add addon to microk8s(order sequence is important)
	microk8s.enable dns
	microk8s.enable dashboard
	microk8s.enable ingress

#### Access dashboard of microk8s(if microk8s is installed on some other VM)
	microk8s.kubectl proxy --accept-hosts=.* --address=0.0.0.0
	microk8s.kubectl proxy --accept-hosts=.* --address=0.0.0.0 & (if want to run in backgroud)

#### To proxy dashboard to localhost(dashboard only works if it accessed from localhost)
##### Windows
	netsh interface portproxy add v4tov4 listenport=8001 
		listenaddress=127.0.0.1 connectport=8001 connectaddress=34.67.40.96
##### Linux
	ssh -L 8001:127.0.0.1:8001 192.0.2.10

#### URL of dashboard
	http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#/login


#### Get secret(dashboard needs password, which can be got from following command)
	token=$(microk8s.kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
	microk8s.kubectl -n kube-system describe secret $token

#### Create plain vanilla deployment
	microk8s.kubectl create deployment microbot --image=dontrebootme/microbot:v1
	microk8s.kubectl scale deployment microbot --replicas=2

#### Update deployment(scale up and scale down)
	microk8s.kubectl scale deployment microbot --replicas=0
	microk8s.kubectl scale deployment microbot --replicas=1

#### Add readyness prob(needed to know k8s if deployment is ready to serve requests)
```
    spec:
      containers:
        - name: k8
          image: 'thebhushanp/k8:ft1.0.1'
          resources: {}
          readinessProbe:
            httpGet:
              path: /api/hello
              port: 8888
              scheme: HTTP
            initialDelaySeconds: 15
            timeoutSeconds: 2
            periodSeconds: 3
            successThreshold: 1
            failureThreshold: 1
```

#### Create service
	microk8s.kubectl expose deployment microbot --type=NodePort
		--port=8888 --name=microbot-service(port 8888 is of the deployment)
	
### Rollback deployment
#### Get history
	microk8s.kubectl rollout history deployment.apps/microbot
#### Rollback to the previous deployed version
	microk8s.kubectl rollout undo deployment.apps/microbot
#### Rollback to a specific previously deployed version
	microk8s.kubectl rollout undo deployment.apps/microbot --to-revision 21

####  Ingress
#### sample of ingress.yml
` ingress.yml`
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: k8s-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:       
  rules:
    - http:
        paths:
          - path: /en(/|$)(.*)
            backend:
              serviceName: d1-service
              servicePort: 8888
          - path: /es(/|$)(.*)
            backend:
              serviceName: d2-service
              servicePort: 8888
```
#### Enable ingress
	microk8s.kubectl apply -f ingress.yml

### Set Spring profile to docker image
` In deployment.yml`
```
spec:
  replicas: 1
  selector:
    matchLabels:
      app: msg
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: msg
    spec:
      containers:
        - name: msg
          image: 'thebhushanp/k8:msg-1.0.3'
          ports:
            - containerPort: 8888
              protocol: TCP
          env:
            - name: '--spring.profiles.active'
              value: k8s
```
`In spring-boot project create application-k8s.yml profile.`

#### Access host's DB
`In deployment.yml`
```
spec:
  replicas: 1
  selector:
    matchLabels:
      app: msg
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: msg
    spec:
      containers:
        - name: msg
          image: 'thebhushanp/k8:msg-1.0.3'
          ports:
            - containerPort: 8888
              protocol: TCP
          env:
            - name: '--spring.profiles.active'
              value: k8s
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: Always
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      schedulerName: default-scheduler
      hostAliases:
        - ip: 10.1.7.1
          hostnames:
            - postgres
            - postgresql
```

` In application-k8s.yml -> jdbc:postgresql://postgresql:5432/legaldb`

` In /etc/postgresql/10/main/pg_hba.conf -> host    all             all             10.1.7.1/24            md5`

#### Check logs of pod
	tail -f /var/log/container/nameOfThePod

## Pending task
1. Log management
2. Resource management(CPU/Memory)
3. Externalization of  config -> etcd/secrets
4. Alerting/monitoring -> Prometheus
5. Autoscalling
6. Helm
7. Use kubernetes of Azure or GCC.
