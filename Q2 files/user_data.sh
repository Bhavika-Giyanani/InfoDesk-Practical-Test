#!/bin/bash
dnf update -y
dnf install -y git nginx
systemctl enable nginx
systemctl start nginx

# Deploy portfolio
git clone https://github.com/Bhavika-Giyanani/Portfolio.git /tmp/portfolio/
rm -rf /usr/share/nginx/html/*
cp -r /tmp/portfolio/* /usr/share/nginx/html/
systemctl reload nginx