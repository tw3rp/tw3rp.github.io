---
layout: post
title: "Solving cert rotation for internal PKI with vault and confd"
comments: true
description: "Solving cert rotation for internal PKI with vault and confd"
keywords: "vault confd automations certs kubernetes"
---

The world is full of webservers with a lot of certificates that need rotation. If you have been managing them,
then you know it is hard to do them correctly. If you have a shiny microservice that you have to ship or you have 
to set up authentication for your webservice with cert based auth and you have a an internal PKI to adhere to then 
it gets hard to scale across all your teams and services to maintain uniformity. Some teams might use cfssl to generate 
a key pair, some might use a self signed cert and this might make your security team very angry.

  There are multiple cloud providers that can solve this issue for you:
1. [AWS ACM](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)
1. [GCE SSL Certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates)

There are various open source tools as well that can help you manage your internal PKI infrastructure as well
some of them are:
1. [cfssl](https://github.com/cloudflare/cfssl) - Which is an opensource project from cloudflare
2. [vault](https://www.vaultproject.io/) - Hashicorps answer to secrets management

In this post I will be going with assumption you have Vault running with PKI configured to issue certs.

### Introduction

This fork of confd can be run with a `-onetime` flag to issue a cert and template into cert and a key file. This is recommended to be a 
short lived cert. Once issued vault does not store the private key for security purposes so it has to be templated right. Once issued it is
not possible to retrieve the private key so the key and value needs to be obtained in a single RPC to vault.

### Pre-requisites

- You have been using [Hashicorp Vault](https://www.vaultproject.io/) for issuing your certs.
- Have docker installed installed
- (optional) to run the following example you would need [jq](https://stedolan.github.io/jq/)

Note: if you don't have a vault instance running or you want to try it out with a local vault instance below is a simple bash script that
sets one up for you with pki configured with just docker installed

{% gist 825e56b8acf41f813ce6297dd6b22bc8 %}

<div class="divider"></div>

### Example Usage

This works as any other confd installation if you've used one before. If you want more details please look [here](http://www.confd.io/)

In this example I will be demonstrating issuing a cert and templating them 

<div class="divider"></div>

#### Configuration

You would need a directory structure as below 

```
etc/
`-- confd
    |-- conf.d
    |   |-- 01-cert-split.toml
    |   `-- 02-cert.toml
    `-- templates
        |-- certkey.pem.tmpl
        `-- split.sh.tmpl
```

The contents of the files are:

*01-cert-split.toml*
```
[template]
mode = "0744"
src = "split.sh.tmpl"
dest = "/tmp/split.sh"
keys = []
```
In the above file we template a bash script to split apart the cert and they key for nix like infra.

*02-cert.toml*
```
[template]
mode = "0644"
src = "certkey.pem.tmpl"
dest = "/tmp/certkey.pem"
keys = [
  "/pki/issue/my-role/www.example.com",
]
reload_cmd = "/tmp/split.sh"
```
In the above script we actually issue the cert by calling the /pki/issue path on vault to get the cert and the key.

*certkey.pem.tmpl*
```
{% raw  %}
{{ if exists "/pki/issue/my-role/www.example.com/certificate" }}
{{- $certificate := getv "/pki/issue/my-role/www.example.com/certificate" -}}
{{- $private_key := getv "/pki/issue/my-role/www.example.com/private_key" -}}
{
    "certificate": "{{ replace $certificate "\n" "\\n" -1 }}",
    "key": "{{ replace $private_key "\n" "\\n" -1 }}"
}
{{end}}
{% endraw %}
```

The above file dumps the cert and the key to a json blob which the script finally splits.

*split.sh.tmpl*
```
#!/bin/bash
cat /tmp/certkey.pem | jq -r .certificate  > /tmp/certificate.pem && chmod 644 /tmp/certificate.pem
cat /tmp/certkey.pem | jq -r .key > /tmp/key.pem && chmod 600 /tmp/key.pem
```

This is the script that splits the json blob to its final destination

<div class="divider"></div>

#### Running

All you need is docker to run this example 

```
docker run --rm --net host -v $(pwd)/etc/confd:/etc/confd -v /tmp:/tmp tw3rp/confd --onetime --log-level debug \
      --backend vaultpki \
      --auth-type token \
      --auth-token myroot \
      --node http://127.0.0.1:8200
```

The final certs are in your tmp folder.


#### Cheers!
