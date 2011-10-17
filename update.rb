root_path = File.expand_path(File.dirname(__FILE__))
require File.join(root_path, "lib", "color")
include Color

def version
  File.read("VERSION")
end

# 
# ruby ./update.rb development # or test or production (default)
#
envs = ["production", "test", "development"]
env = if envs.include?(ARGV[0])
        ARGV[0]
      else
        "production"
      end

puts yellow "== RAILS ENV | #{env}"
current_version = version
puts yellow "Your version is #{current_version}"
puts yellow "Check for new version: $ git pull origin"
`git pull origin` # pull from origin

# latest version
if version == current_version
  puts yellow "You have a latest version"
else
  puts green "Update to #{version}"

`bundle install`

  # migrate db
if env == "development"
`bundle exec rake db:migrate RAILS_ENV=development`
`bundle exec rake db:migrate RAILS_ENV=test`
else
`bundle exec rake db:migrate RAILS_ENV=#{env}`
end

  puts green "== Done! Now you can start/restart server"
end


