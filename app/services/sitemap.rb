require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://ljsave.com'
SitemapGenerator::Sitemap.create do
  Dir.glob('public/lj/**/*.html').each do |file|
    basename = File.basename(file)
    next unless basename =~ /^\d+.html$/
    add file.delete_prefix('public')
  end
end
# SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks