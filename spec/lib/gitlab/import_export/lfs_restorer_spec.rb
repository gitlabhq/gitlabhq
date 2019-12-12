# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::LfsRestorer do
  include UploadHelpers

  let(:export_path) { "#{Dir.tmpdir}/lfs_object_restorer_spec" }
  let(:project) { create(:project) }
  let(:shared) { project.import_export_shared }
  let(:saver) { Gitlab::ImportExport::LfsSaver.new(project: project, shared: shared) }

  subject(:restorer) { described_class.new(project: project, shared: shared) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#restore' do
    context 'when the archive contains lfs files' do
      let(:lfs_object) { create(:lfs_object, :correct_oid, :with_file) }

      # Use the LfsSaver to save data to be restored
      def save_lfs_data
        %w(project wiki).each do |repository_type|
          create(
            :lfs_objects_project,
            project: project,
            repository_type: repository_type,
            lfs_object: lfs_object
          )
        end

        saver.save

        project.lfs_objects.delete_all
      end

      before do
        save_lfs_data
        project.reload
      end

      it 'succeeds' do
        expect(restorer.restore).to eq(true)
        expect(shared.errors).to be_empty
      end

      it 'does not create a new `LfsObject` records, as one already exists' do
        expect { restorer.restore }.not_to change { LfsObject.count }
      end

      it 'creates new `LfsObjectsProject` records in order to link the project to the existing `LfsObject`' do
        expect { restorer.restore }.to change { LfsObjectsProject.count }.by(2)
      end

      it 'restores the correct `LfsObject` records' do
        restorer.restore

        expect(project.lfs_objects).to contain_exactly(lfs_object)
      end

      it 'restores the correct `LfsObjectsProject` records for the project' do
        restorer.restore

        expect(
          project.lfs_objects_projects.pluck(:repository_type)
        ).to contain_exactly('project', 'wiki')
      end

      it 'assigns the file correctly' do
        restorer.restore

        expect(project.lfs_objects.first.file.read).to eq(lfs_object.file.read)
      end

      context 'when there is not an existing `LfsObject`' do
        before do
          lfs_object.destroy
        end

        it 'creates a new lfs object' do
          expect { restorer.restore }.to change { LfsObject.count }.by(1)
        end

        it 'stores the upload' do
          expect_any_instance_of(LfsObjectUploader).to receive(:store!)

          restorer.restore
        end
      end

      context 'when there is no lfs-objects.json file' do
        before do
          json_file = File.join(shared.export_path, ::Gitlab::ImportExport.lfs_objects_filename)

          FileUtils.rm_rf(json_file)
        end

        it 'restores the correct `LfsObject` records' do
          restorer.restore

          expect(project.lfs_objects).to contain_exactly(lfs_object)
        end

        it 'restores a single `LfsObjectsProject` record for the project with "project" for the `repository_type`' do
          restorer.restore

          expect(
            project.lfs_objects_projects.pluck(:repository_type)
          ).to contain_exactly('project')
        end
      end
    end

    context 'without any LFS-objects' do
      it 'succeeds' do
        expect(restorer.restore).to be_truthy
        expect(shared.errors).to be_empty
      end
    end
  end
end
