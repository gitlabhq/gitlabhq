RSpec.configure do |config|
  config.around(:each, :allow_forgery_protection) do |example|
    begin
      ActionController::Base.allow_forgery_protection = true

      example.call
    ensure
      ActionController::Base.allow_forgery_protection = false
    end
  end
end
