RSpec.configure do |config|
  config.before(:each) do |example|
    next if example.metadata[:skip_gitaly_mock]
    allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(true)
  end
end
