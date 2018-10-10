RSpec.configure do |config|
  config.before(:all, :broken_storage) do
    FileUtils.rm_rf Gitlab.config.repositories.storages.broken.legacy_disk_path
  end

  config.before(:each, :broken_storage) do
    allow(Gitlab::GitalyClient).to receive(:call) do
      raise GRPC::Unavailable.new('Gitaly broken in this spec')
    end
  end
end
