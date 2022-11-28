# QGIS server debug container

Docker container for QGIS server similar to the one provided by the official docs, but compiled in debug mode in order to have access to detailed logging data.

This will allow you to set QGIS_DEBUG env variable to make QGIS print debug info. By default, debug mode uses `QGIS_DEBUG=1` with moderate amount of output, to get very verbose output, go with `QGIS_DEBUG=4`

See https://docs.qgis.org/3.28/en/docs/server_manual/containerized_deployment.html for original QGIS server instructions.

To build this container:

```
docker build -f Dockerfile -t qgis-server-debug .
```

## How to run

You will need to run two containers:

1. qgis server container (provides FastCGI process)
2. nginx container (takes HTTP traffic and passes it to QGIS server)

To run QGIS server - assuming your project is in `/home/martin/server-data/my-project.qgz`:

```
docker run --rm -it --name qgis-server-debug --network host \
  -v /home/martin/server-data:/data:ro \
  -e QGIS_PROJECT_FILE=/data/my-project.qgz \
  -e QGIS_DEBUG=4 \
  qgis-server-debug
```

To run nginx:

```
docker run --rm --name nginx --network host \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:1.13
```

## How to use

In QGIS, define a WMS connection using this URL: `http://localhost:8080/qgis-server/`

In web browser, test the GetCapabilities URL: `http://localhost:8080/qgis-server/?REQUEST=GetCapabilities&SERVICE=WMS`
