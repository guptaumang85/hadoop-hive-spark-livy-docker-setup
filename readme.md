# Hadoop-Hive-Spark cluster on Docker

## Caution
Do not use in a production environment

## Software

* [Hadoop 3.3.6](https://hadoop.apache.org/)

* [Hive 3.1.3](http://hive.apache.org/)

* [Spark 3.3.2](https://spark.apache.org/)

* [Livy 0.8.0](https://livy.apache.org/)

## Quick Start

To deploy the cluster, run:
```sh
make build
```

```sh
docker-compose up -d
```

## Access interfaces with the following URL

### Hadoop

ResourceManager: http://localhost:8088

NameNode: http://localhost:9870

HistoryServer: http://localhost:19888

Datanode1: http://localhost:9864
Datanode2: http://localhost:9865

NodeManager1: http://localhost:8042
NodeManager2: http://localhost:8043

### Spark
master: http://localhost:8080

worker1: http://localhost:8081
worker2: http://localhost:8082
