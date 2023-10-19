# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:dependency_proxy namespace rake task', :silence_stdout do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/dependency_proxy/migrate'
  end

  describe 'migrate' do
    let(:local) { ObjectStorage::Store::LOCAL }
    let(:remote) { ObjectStorage::Store::REMOTE }
    let!(:blob) { create(:dependency_proxy_blob) }
    let!(:manifest) { create(:dependency_proxy_manifest) }

    def dependency_proxy_migrate
      run_rake_task('gitlab:dependency_proxy:migrate')
    end

    context 'object storage disabled' do
      before do
        stub_dependency_proxy_object_storage(enabled: false)
      end

      it "doesn't migrate files" do
        expect { dependency_proxy_migrate }.to raise_error('Object store is disabled for dependency proxy feature')
      end
    end

    context 'object storage enabled' do
      before do
        stub_dependency_proxy_object_storage
      end

      it 'migrates local file to object storage' do
        expect { dependency_proxy_migrate }.to change { blob.reload.file_store }.from(local).to(remote)
          .and change { manifest.reload.file_store }.from(local).to(remote)
      end
    end

    context 'an error is raised while migrating' do
      let(:blob_error) { 'Failed to transfer dependency proxy blob file' }
      let(:manifest_error) { 'Failed to transfer dependency proxy manifest file' }
      let!(:blob_non_existent) { create(:dependency_proxy_blob) }
      let!(:manifest_non_existent) { create(:dependency_proxy_manifest) }

      before do
        stub_dependency_proxy_object_storage
        blob_non_existent.file.file.delete
        manifest_non_existent.file.file.delete
      end

      it 'fails to migrate a local file that does not exist' do
        expect { dependency_proxy_migrate }.to output(include(blob_error, manifest_error)).to_stdout
      end
    end
  end
end
