







```shell
docker run -d \
--name vsftpd   \
--restart=always \
-v /data/ftp/data/:/home/vsftpd \
-v  /data/ftp/log/:/var/log/vsftpd/ \
-p 20:20 -p 21:21 -p 20000:20000 \
-e FTP_USER=admin \
-e FTP_PASS=admin \
-e PASV_MIN_PORT=20000 \
-e PASV_MAX_PORT=20000 \
-e PASV_ADDRESS=192.168.3.166 \
-e LOG_STDOUT=1 \
fauria/vsftpd

```

