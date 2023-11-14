# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::LfsSaver do
  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:project) { create(:project) }

  subject(:saver) { described_class.new(project: project, shared: shared) }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#save' do
    context 'when the project has LFS objects locally stored' do
      let(:lfs_object) { create(:lfs_object, :with_file) }
      let(:lfs_json_file) { File.join(shared.export_path, Gitlab::ImportExport.lfs_objects_filename) }

      def lfs_json
        Gitlab::Json.parse(File.read(lfs_json_file))
      end

      before do
        project.lfs_objects << lfs_object
      end

      it 'does not cause errors' do
        saver.save # rubocop:disable Rails/SaveBang

        expect(shared.errors).to be_empty
      end

      it 'copies the file in the correct location when there is an lfs object' do
        saver.save # rubocop:disable Rails/SaveBang

        expect(File).to exist("#{shared.export_path}/lfs-objects/#{lfs_object.oid}")
      end

      context 'when lfs object has file on disk missing' do
        it 'does not attempt to copy non-existent file' do
          FileUtils.rm(lfs_object.file.path)
          expect(saver).not_to receive(:copy_files)

          saver.save # rubocop:disable Rails/SaveBang

          expect(shared.errors).to be_empty
          expect(File).not_to exist("#{shared.export_path}/lfs-objects/#{lfs_object.oid}")
        end
      end

      describe 'saving a json file' do
        before do
          # Create two more LfsObjectProject records with different `repository_type`s
          %w[wiki design].each do |repository_type|
            create(
              :lfs_objects_project,
              project: project,
              repository_type: repository_type,
              lfs_object: lfs_object
            )
          end

          FileUtils.rm_rf(lfs_json_file)
        end

        it 'saves a json file correctly' do
          saver.save # rubocop:disable Rails/SaveBang

          expect(File.exist?(lfs_json_file)).to eq(true)
          expect(lfs_json).to eq(
            {
              lfs_object.oid => [
                LfsObjectsProject.repository_types['wiki'],
                LfsObjectsProject.repository_types['design'],
                nil
              ]
            }
          )
        end
      end
    end

    context 'when the LFS objects are stored in object storage' do
      let(:lfs_object) { create(:lfs_object, :object_storage) }

      before do
        allow(LfsObjectUploader).to receive(:object_store_enabled?).and_return(true)
        project.lfs_objects << lfs_object

        expect_next_instance_of(LfsObjectUploader) do |instance|
          expect(instance).to receive(:url).and_return('http://my-object-storage.local')
        end
      end

      it 'downloads the file to include in an archive' do
        fake_uri = double
        exported_file_path = "#{shared.export_path}/lfs-objects/#{lfs_object.oid}"

        expect(fake_uri).to receive(:open).and_return(StringIO.new('LFS file content'))
        expect(URI).to receive(:parse).with('http://my-object-storage.local').and_return(fake_uri)

        saver.save # rubocop:disable Rails/SaveBang

        expect(File.read(exported_file_path)).to eq('LFS file content')
      end
    end
  end
end
