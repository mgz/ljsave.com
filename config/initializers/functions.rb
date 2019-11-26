def putsd(*args)
  if ENV['DEBUG_LOG'] == '1'
    puts args
  end
end

OPERA_USERAGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.87 Safari/537.36 OPR/37.0.2178.31'

def read_url(url, opts: {})
  require 'open-uri'
  if (proxy = ENV['PROXY'])
    proxy = "http://#{proxy}" unless proxy.start_with?('http://')
    opts[:proxy] = URI.parse(proxy)
    opts['User-Agent'] = OPERA_USERAGENT
  end
  
  return open(url, opts).read
end
