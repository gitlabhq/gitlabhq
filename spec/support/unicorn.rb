# frozen_string_literal: true

REQUEST_CLASSES = [
  ::Grape::Request,
  ::Rack::Request
].freeze

def request_body_class
  return ::Unicorn::TeeInput if defined?(::Unicorn)

  Class.new(StringIO) do
    def string
      raise NotImplementedError, '#string is only valid under Puma which uses StringIO, use #read instead'
    end
  end
end

RSpec.configure do |config|
  config.before(:each, :unicorn) do
    REQUEST_CLASSES.each do |request_class|
      allow_any_instance_of(request_class)
        .to receive(:body).and_wrap_original do |m, *args|
          request_body_class.new(m.call(*args).read)
        end
    end
  end
end
