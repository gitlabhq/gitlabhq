RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:disable_gitaly]
      allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)
    else
      next if example.metadata[:skip_gitaly_mock]

      allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(true)
    end
  end
end
