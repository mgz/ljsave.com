#!/usr/bin/env bash

apt update
apt install -y curl
apt clean
rm -rf /var/lib/apt/lists/*
