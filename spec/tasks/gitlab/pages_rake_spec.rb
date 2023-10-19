# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:pages', :silence_stdout do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/pages'
  end

  describe 'gitlab:pages:deployments:migrate_to_object_storage' do
    subject { run_rake_task('gitlab:pages:deployments:migrate_to_object_storage') }

    before do
      stub_pages_object_storage(::Pages::DeploymentUploader, enabled: object_storage_enabled)
    end

    let!(:deployment) { create(:pages_deployment, file_store: store) }
    let(:object_storage_enabled) { true }

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      context 'and remote storage is defined' do
        it 'migrates file to remote storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'and remote storage is not defined' do
        let(:object_storage_enabled) { false }

        it 'fails to migrate to remote storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when remote storage is used' do
      let(:store) { ObjectStorage::Store::REMOTE }

      it 'file stays on remote storage' do
        subject

        expect(deployment.reload.file_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end
  end

  describe 'gitlab:pages:deployments:migrate_to_local' do
    subject { run_rake_task('gitlab:pages:deployments:migrate_to_local') }

    before do
      stub_pages_object_storage(::Pages::DeploymentUploader, enabled: object_storage_enabled)
    end

    let!(:deployment) { create(:pages_deployment, file_store: store) }
    let(:object_storage_enabled) { true }

    context 'when remote storage is used' do
      let(:store) { ObjectStorage::Store::REMOTE }

      context 'and job has remote file store defined' do
        it 'migrates file to local storage' do
          subject

          expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end

    context 'when local storage is used' do
      let(:store) { ObjectStorage::Store::LOCAL }

      it 'file stays on local storage' do
        subject

        expect(deployment.reload.file_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
