module GitHelpers
  def random_git_name
    "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"
  end
end

RSpec.configure do |config|
  config.include GitHelpers
end
