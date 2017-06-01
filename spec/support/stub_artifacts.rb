module StubConfiguration
  def stub_artifacts_object_storage(enabled: true)
    Fog.mock!
    allow(Gitlab.config.artifacts.object_store).to receive_messages(
      enabled: enabled,
      remote_directory: 'artifacts',
      connection: {
        provider: 'AWS',
        aws_access_key_id: 'AWS_ACCESS_KEY_ID',
        aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY',
        region: 'eu-central-1'
      }
    )

    ::Fog::Storage.new(Gitlab.config.artifacts.object_store.connection).tap do |connection|
      begin
        connection.directories.create(key: 'artifacts')
      rescue Excon::Error::Conflict
      end
    end if enabled
  end
end
