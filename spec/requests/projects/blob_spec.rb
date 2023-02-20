# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Blobs', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository, lfs: true) }

  describe 'GET /:namespace_id/:project_id/-/blob/:id' do
    subject(:request) do
      get namespace_project_blob_path(namespace_id: project.namespace, project_id: project, id: id)
    end

    context 'with LFS file' do
      let(:id) { 'master/files/lfs/lfs_object.iso' }
      let(:object_store_host) { 'http://127.0.0.1:9000' }
      let(:connect_src) do
        csp = response.headers['Content-Security-Policy']
        csp.split('; ').find { |src| src.starts_with?('connect-src') }
      end

      let(:gitlab_config) do
        Gitlab.config.gitlab.deep_merge(
          'content_security_policy' => {
            'enabled' => content_security_policy_enabled
          }
        )
      end

      let(:lfs_config) do
        Gitlab.config.lfs.deep_merge(
          'enabled' => lfs_enabled,
          'object_store' => {
            'remote_directory' => 'lfs-objects',
            'enabled' => true,
            'proxy_download' => proxy_download,
            'connection' => {
              'endpoint' => object_store_host,
              'path_style' => true
            }
          }
        )
      end

      before do
        stub_config_setting(gitlab_config)
        stub_lfs_setting(lfs_config)
        stub_lfs_object_storage(proxy_download: proxy_download)

        request
      end

      describe 'directly downloading lfs file' do
        let(:lfs_enabled) { true }
        let(:proxy_download) { false }
        let(:content_security_policy_enabled) { true }

        it { expect(response).to have_gitlab_http_status(:success) }

        it { expect(connect_src).to include(object_store_host) }

        context 'when lfs is disabled' do
          let(:lfs_enabled) { false }

          it { expect(response).to have_gitlab_http_status(:success) }

          it { expect(connect_src).not_to include(object_store_host) }
        end

        context 'when content_security_policy is disabled' do
          let(:content_security_policy_enabled) { false }

          it { expect(response).to have_gitlab_http_status(:success) }

          it { expect(connect_src).not_to include(object_store_host) }
        end

        context 'when proxy download is enabled' do
          let(:proxy_download) { true }

          it { expect(response).to have_gitlab_http_status(:success) }

          it { expect(connect_src).not_to include(object_store_host) }
        end
      end
    end
  end
end
