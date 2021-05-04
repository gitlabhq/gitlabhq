# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :broken_storage) do
    allow(Gitlab::GitalyClient).to receive(:call) do
      raise GRPC::Unavailable, 'Gitaly broken in this spec'
    end
  end
end
