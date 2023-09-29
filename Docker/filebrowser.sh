#!/bin/bash
docker run -d --name filebrowser --restart unless-stopped -e TZ=Asia/Singapore -p 8080:80 -v /:/srv filebrowser/filebrowser
