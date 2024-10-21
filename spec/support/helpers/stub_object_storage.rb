# frozen_string_literal: true

module StubObjectStorage
  def stub_dependency_proxy_object_storage(**params)
    stub_object_storage_uploader(
      config: ::Gitlab.config.dependency_proxy.object_store,
      uploader: ::DependencyProxy::FileUploader,
      **params
    )
  end

  def stub_object_storage_uploader(
    config:,
    uploader:,
    enabled: true,
    proxy_download: false,
    direct_upload: false,
    cdn: {}
  )
    old_config = ::GitlabSettings::Options.build(config.to_h.deep_stringify_keys)
    new_config = config.to_h.deep_symbolize_keys.merge({
      enabled: enabled,
      proxy_download: proxy_download,
      direct_upload: direct_upload,
      cdn: cdn
    })

    # Needed for ObjectStorage::Config compatibility
    allow(config).to receive(:to_hash).and_return(new_config)
    allow(config).to receive(:to_h).and_return(new_config)
    allow(config).to receive(:enabled) { enabled }
    allow(config).to receive(:proxy_download) { proxy_download }
    allow(config).to receive(:direct_upload) { direct_upload }

    uploader_config = ::GitlabSettings::Options.build(new_config.to_h.deep_stringify_keys)
    allow(uploader).to receive(:object_store_options).and_return(uploader_config)
    allow(uploader.options).to receive(:object_store).and_return(uploader_config)

    return unless enabled

    stub_object_storage(
      connection_params: uploader.object_store_credentials,
      remote_directory: old_config.remote_directory
    )
  end

  def stub_object_storage(connection_params:, remote_directory:)
    Fog.mock!

    ::Fog::Storage.new(connection_params).tap do |connection|
      connection.directories.create(key: remote_directory) # rubocop:disable Rails/SaveBang

      # Cleanup remaining files
      connection.directories.each do |directory|
        directory.files.map(&:destroy)
      end
    rescue Excon::Error::Conflict
    end
  end

  def stub_artifacts_object_storage(uploader = JobArtifactUploader, **params)
    stub_object_storage_uploader(
      config: Gitlab.config.artifacts.object_store,
      uploader: uploader,
      **params
    )
  end

  def stub_external_diffs_object_storage(uploader = described_class, **params)
    stub_object_storage_uploader(
      config: Gitlab.config.external_diffs.object_store,
      uploader: uploader,
      **params
    )
  end

  def stub_lfs_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.lfs.object_store,
      uploader: LfsObjectUploader,
      **params
    )
  end

  def stub_package_file_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.packages.object_store,
      uploader: ::Packages::PackageFileUploader,
      **params
    )
  end

  def stub_rpm_repository_file_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.packages.object_store,
      uploader: ::Packages::Rpm::RepositoryFileUploader,
      **params
    )
  end

  def debian_component_file_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.packages.object_store,
      uploader: ::Packages::Debian::ComponentFileUploader,
      **params
    )
  end

  def debian_distribution_release_file_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.packages.object_store,
      uploader: ::Packages::Debian::DistributionReleaseFileUploader,
      **params
    )
  end

  def stub_uploads_object_storage(uploader = described_class, **params)
    stub_object_storage_uploader(
      config: Gitlab.config.uploads.object_store,
      uploader: uploader,
      **params
    )
  end

  def stub_ci_secure_file_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.ci_secure_files.object_store,
      uploader: Ci::SecureFileUploader,
      **params
    )
  end

  def stub_terraform_state_object_storage(**params)
    stub_object_storage_uploader(
      config: Gitlab.config.terraform_state.object_store,
      uploader: Terraform::StateUploader,
      **params
    )
  end

  def stub_pages_object_storage(uploader = described_class, **params)
    stub_object_storage_uploader(
      config: Gitlab.config.pages.object_store,
      uploader: uploader,
      **params
    )
  end

  def stub_object_storage_multipart_init(endpoint, upload_id = "upload_id")
    stub_request(:post, %r{\A#{endpoint}tmp/uploads/[%A-Za-z0-9-]*\?uploads\z})
      .to_return status: 200, body: <<-EOS.strip_heredoc
        <?xml version="1.0" encoding="UTF-8"?>
        <InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Bucket>example-bucket</Bucket>
          <Key>example-object</Key>
          <UploadId>#{upload_id}</UploadId>
        </InitiateMultipartUploadResult>
      EOS
  end

  def stub_object_storage_multipart_init_with_final_store_path(full_path, upload_id = "upload_id")
    stub_request(:post, %r{\A#{full_path}\?uploads\z})
      .to_return status: 200, body: <<-EOS.strip_heredoc
        <?xml version="1.0" encoding="UTF-8"?>
        <InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Bucket>example-bucket</Bucket>
          <Key>example-object</Key>
          <UploadId>#{upload_id}</UploadId>
        </InitiateMultipartUploadResult>
      EOS
  end
end
