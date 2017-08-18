module StubConfiguration
  def stub_artifacts_object_storage(enabled: true)
    Fog.mock!

    allow(Gitlab.config.artifacts.object_store).to receive(:enabled) { enabled }
    allow_any_instance_of(ArtifactUploader).to receive(:verify_license!) { true }

    return unless enabled

    ::Fog::Storage.new(ArtifactUploader.object_store_credentials).tap do |connection|
      begin
        connection.directories.create(key: 'artifacts')
      rescue Excon::Error::Conflict
      end
    end
  end
end
