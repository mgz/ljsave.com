docker build -t ljdownload . && docker run --rm -v $(pwd)/out:/out -it ljdownload /bin/bash


var jq = document.createElement('script');
jq.src = "https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(jq);
// ... give time for script to load, then type (or see below for non wait option)
jQuery.noConflict();



```bash
NO_WGET=0 CLEAR_CACHE=0 NO_HEADLESS=0 PROXY=localhost:8117 bundle exec ruby go.rb palaman
NO_WGET=1 USE_CACHE=1 bundle exec ruby -r './user.rb' -e 'Dir.glob("../../../out/*.html").map{|f| File.basename(f, ".html")}.each{|username| User.new(username).rebuild_index_file}'
```

ljbackup
ljcopy
ljmirrors
ljsave

