docker build -t ljsave . && docker run --rm -v $(pwd)/scraped:/scraped -v $(pwd)/public/lj:/public/lj -e DEBUG_LOG=1 -e USE_CACHE=1 -e PROXY='http://localhost:8118' -e RAILS_ENV=production ljsave bundle exec rake scraper:download username=galkovsky 


DEBUG_LOG=1 USE_CACHE=1 PROXY='http://localhost:8118' bundle exec rake scraper:download username=galkovsky RAILS_ENV=production
