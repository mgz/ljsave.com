#!/usr/bin/env bash
set -e

apt update && \
apt install -y software-properties-common && \
apt-add-repository ppa:brightbox/ruby-ng && \
apt update && \
apt install -y ruby2.6 ruby2.6-dev build-essential zlib1g-dev && \
apt clean && \
rm -rf /var/lib/apt/lists/* && \
gem install selenium-webdriver httparty nokogiri activesupport parallel # --no-rdoc --no-ri
#gem install selenium-webdriver browserstack-webdriver httparty nokogiri activesupport # --no-rdoc --no-ri
