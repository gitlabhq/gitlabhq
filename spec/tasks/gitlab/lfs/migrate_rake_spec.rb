# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:lfs namespace rake task', :silence_stdout do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/lfs/migrate'
  end

  context 'migration tasks' do
    let(:local) { ObjectStorage::Store::LOCAL }
    let(:remote) { ObjectStorage::Store::REMOTE }

    before do
      stub_lfs_object_storage(direct_upload: false)
    end

    describe 'migrate' do
      subject { run_rake_task('gitlab:lfs:migrate') }

      let!(:lfs_object) { create(:lfs_object, :with_file) }

      context 'object storage disabled' do
        before do
          stub_lfs_object_storage(enabled: false)
        end

        it "doesn't migrate files" do
          expect { subject }.not_to change { lfs_object.reload.file_store }
        end
      end

      context 'object storage enabled' do
        it 'migrates local file to object storage' do
          expect { subject }.to change { lfs_object.reload.file_store }.from(local).to(remote)
        end
      end
    end

    describe 'migrate_to_local' do
      subject { run_rake_task('gitlab:lfs:migrate_to_local') }

      let(:lfs_object) { create(:lfs_object, :with_file, :object_storage) }

      before do
        stub_lfs_object_storage(direct_upload: true)
      end

      context 'object storage enabled' do
        it 'migrates remote files to local storage' do
          expect { subject }.to change { lfs_object.reload.file_store }.from(remote).to(local)
        end
      end
    end
  end
end
