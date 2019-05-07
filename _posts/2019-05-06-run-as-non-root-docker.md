---
layout: post
title: "Running as non root inside the docker container"
comments: true
description: "Running all processes inside the docker container as non root for security"
keywords: "docker security not root kubernetes"
---

As we came across the [vulnerability](https://kubernetes.io/blog/2019/02/11/runc-and-cve-2019-5736/) when a process can assume root and change the runc binary
on the host. There is much need to make sure containers are not run as root and dont have access to write to files in group 0 (root). With kubernetes being 
increasingly used by many organizations and companies, the amount of work and time required to implement the fix when such vulnerabilities come to light becomes
expensive. There are simple workarounds that you can put in place so we can avoid doing the heavilifting at a later time. 

### One simple fix

Below is an example of a Dockerfile that you can use to build the container so you can make sure you are running as non root by default
**Dockerfile**

```
FROM alpine

# create the docker user and group and chown the home dir
RUN groupadd -r docker -g 1000 -f && \
	useradd -r -g 1000 -u 9999 -d /home/docker -s /sbin/nologin -c "Docker user" docker && \
  mkdir -p /home/docker && \
  chown -R docker:docker /home/docker

# become docker user
USER docker

# Meat of the build
```

Now once you build it always runs as this non root user and you can run it on your favorite container orchestration mechanism. 

Cheers!
