if ENV['SIMPLECOV']
  require 'simplecov'
end

if ENV['COVERALLS']
  require 'coveralls'
  Coveralls.wear_merged!
end
