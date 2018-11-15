#!/bin/bash
docker run -d --restart always --name=gogs_amd64  -p 3022:3022 -p 3000:3000 -v /data/gogs/ssh:/opt/gogs/.ssh -v /data/gogs/data:/data kdedesign/gogs_amd64:latest
