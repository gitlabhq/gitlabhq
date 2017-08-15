RSpec.configure do |config|
  config.before(:each, :repository) do
    TestEnv.clean_test_path
  end

  config.before(:all, :broken_storage) do
    FileUtils.rm_rf Gitlab.config.repositories.storages.broken['path']
  end

  config.before(:each, :broken_storage) do
    allow(Gitlab::GitalyClient).to receive(:call) do
      raise GRPC::Unavailable.new('Gitaly broken in this spec')
    end

    Gitlab::Git::Storage::CircuitBreaker.reset_all!
  end
end
