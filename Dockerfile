FROM ruby:2.6

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN apt-get update -qq && apt-get install -y nodejs libnss3 libgconf-2-4

RUN echo "Installing chromedriver" \
&& wget https://chromedriver.storage.googleapis.com/LATEST_RELEASE \
&& wget https://chromedriver.storage.googleapis.com/`cat LATEST_RELEASE`/chromedriver_linux64.zip \
&& unzip chromedriver_linux64.zip \
&& mv chromedriver /usr/bin/

# Copy app and install gems
RUN mkdir -p /home/app/webapp
WORKDIR /home/app/webapp
COPY Gemfile Gemfile.lock ./
RUN gem install bundler &&  bundle config --global silence_root_warning 1 && bundle install --jobs 20 --retry 5 --deployment --without development test

COPY  . .
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
