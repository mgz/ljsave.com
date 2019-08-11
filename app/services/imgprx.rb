class Imgprx
  def self.fix
    puts 'Searching...'
    files_to_fix = `grep -l --include='[0123456789]*.html' -r . -e 'https://imgprx.livejournal.net'`
    puts "Found #{files_to_fix.size} files to fix"
  end
end