# Dia 1

### Paso 1
Creación del cluster
```
alefi@fineloq:~$ eksctl create cluster \
  --name aw-bootcamp-cluster \
  --region us-east-1 \
  --nodes 1 \
  --node-type t3.small \
  --managed
```

### Paso 2
Verificación de cluster y descarga de credenciales

```
alefi@fineloq:~$ aws eks --region us-east-1 update-kubeconfig --name aw-bootcamp-cluster

Added new context arn:aws:eks:us-east-1:711387135481:cluster/aw-bootcamp-cluster to /home/alefi/.kube/confi

```

### Paso 3


```
alefi@fineloq:~/aqua/aw-devops-platform$ cd app
alefi@fineloq:~/aqua/aw-devops-platform/app$ cat > index.php <<'EOF'
<?php
echo "<h1>aw-bootcamp Day 1</h1>";
echo "<p>Aplicaciòn corriendo en contenedor</p>";
echo "<p>Hostname: " . gethostname() . "</p>";
phpinfo();
EOF
alefi@fineloq:~/aqua/aw-devops-platform/app$ 

```

### Paso 4

```
cat > Dockerfile <<'EOF'
FROM php:8.1-apache
COPY index.php /var/www/html/
EXPOSE 80
EOF

```

### Paso 5

```
alefi@fineloq:~/aqua/aw-devops-platform/app$ docker build -t aw-sample:local .

```

### Paso 6

```
alefi@fineloq:~/aqua/aw-devops-platform/app$ docker build -t aw-sample:local .

alefi@fineloq:~/aqua/aw-devops-platform/app$ docker run --rm -p 8080:80 aw-sample:local

```