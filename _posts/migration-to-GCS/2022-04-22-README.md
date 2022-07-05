---
title: "Data migration to Cloud Storage"
---

## migration to GCS by SFTP

[Cloud Storage FUSE](https://cloud.google.com/storage/docs/gcs-fuse?hl=ko)를 통해  Cloud Storage를 마운트하여 VM이나 로컬에서 마운트된 폴더에서 파일을 다운로드받는다. 

Cloud Storage FUSE는 Cloud Storage 버킷을 Linux나 macOS 시스템에 파일 시스템으로 마운트할 수 있는 오픈소스 FUSE 어댑터로, I/O 코드를 다시 쓸 필요 없이 Cloud Storage 업로드, 다운로드를 빠르게 할 수 있다.

### setup
```console
$ BUCKET_NAME = 'nasdaq-totalview-itch-historical'
$ export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
$ echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
$ curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ sudo apt-get update
$ sudo apt-get install gcsfuse
$ # export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/$ACCOUNT_NAME.json
$ mkdir ~/${BUCKET_NAME}
$ gcsfuse ${BUCKET_NAME} ~/${BUCKET_NAME}
```

## S3 to GCS

S3에서 GCS로 migration하는 데 몇 가지 고려할 방안이 있다. 

1. GCP Data Transfer를 사용한다 : access key ID와 secret access key를 알아야 사용가능( 계정을 사용할 수 없으면 사용 불가하다. ) 
> 참고 : [How to process files from Amazon S3 using GCS bucket](https://documentation.maptiler.com/hc/en-us/articles/360020806377-How-to-process-files-from-Amazon-S3-using-GCS-bucket)

![](Untitled.png) 

2. NYSE 데이터를 받기 위한 ec2에 접속해서 해당 환경에서 gsutil로 이전한다.  
> 참고 : [Intro to Transferring Files Between AWS S3 and GCS](https://medium.com/@velasquez.tim117/intro-to-transferring-files-between-aws-s3-and-gcs-e2fe68bbe5ec)

3. REST API 요청을 통해 이전한다.  
> 참고 : [Migrate from Amazon S3 to Cloud Storage](https://cloud.google.com/storage/docs/migrating)

