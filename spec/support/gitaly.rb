if Gitlab::GitalyClient.enabled?
  RSpec.configure do |config|
    config.before(:each) do
      allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(true)
    end
  end
end
