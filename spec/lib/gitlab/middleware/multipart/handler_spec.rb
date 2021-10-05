# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::Multipart::Handler do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:env) { Rack::MockRequest.env_for('/', method: 'post', params: {}) }
  let_it_be(:message) { { 'rewritten_fields' => {} } }

  describe '#allowed_paths' do
    let_it_be(:expected_allowed_paths) do
      [
        Dir.tmpdir,
        ::FileUploader.root,
        ::Gitlab.config.uploads.storage_path,
        ::JobArtifactUploader.workhorse_upload_path,
        ::LfsObjectUploader.workhorse_upload_path,
        ::DependencyProxy::FileUploader.workhorse_upload_path,
        File.join(Rails.root, 'public/uploads/tmp')
      ]
    end

    let_it_be(:expected_with_packages_path) { expected_allowed_paths + [::Packages::PackageFileUploader.workhorse_upload_path] }

    subject { described_class.new(env, message).send(:allowed_paths) }

    where(:package_features_enabled, :object_storage_enabled, :direct_upload_enabled, :expected_paths) do
      false | false | true  | :expected_allowed_paths
      false | false | false | :expected_allowed_paths
      false | true  | true  | :expected_allowed_paths
      false | true  | false | :expected_allowed_paths
      true  | false | true  | :expected_with_packages_path
      true  | false | false | :expected_with_packages_path
      true  | true  | true  | :expected_allowed_paths
      true  | true  | false | :expected_with_packages_path
    end

    with_them do
      before do
        stub_config(packages: {
          enabled: package_features_enabled,
          object_store: {
            enabled: object_storage_enabled,
            direct_upload: direct_upload_enabled
          },
          storage_path: '/any/dir'
        })
      end

      it { is_expected.to eq(send(expected_paths)) }
    end
  end
end
