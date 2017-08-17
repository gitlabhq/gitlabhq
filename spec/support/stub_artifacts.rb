module StubConfiguration
  def stub_artifacts_object_storage(enabled: true)
    Fog.mock!
    object_store = Settingslogic.new(
      'enabled' => enabled,
      'remote_directory' => 'artifacts',
      'connection' => Settingslogic.new(
        'provider' => 'AWS',
        'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
        'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
        'region' => 'eu-central-1'
      )
    )

    allow(Gitlab.config.artifacts).to receive(:object_store) { object_store }
    allow_any_instance_of(ArtifactUploader).to receive(:verify_license!) { true }

    return unless enabled

    ::Fog::Storage.new(Gitlab.config.artifacts.object_store.connection).tap do |connection|
      begin
        connection.directories.create(key: 'artifacts')
      rescue Excon::Error::Conflict
      end
    end
  end
end
