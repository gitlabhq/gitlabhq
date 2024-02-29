# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lfs::FileTransformer, feature_category: :source_code_management do
  let(:project) { create(:project, :repository, :wiki_repo) }
  let(:repository) { project.repository }
  let(:file_content) { 'Test file content' }
  let(:branch_name) { 'lfs' }
  let(:file_path) { 'test_file.lfs' }

  subject { described_class.new(project, repository, branch_name) }

  describe '#new_file' do
    context 'with lfs disabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'skips gitattributes check' do
        expect(repository.raw).not_to receive(:blob_at)

        subject.new_file(file_path, file_content)
      end

      it 'returns untransformed content' do
        result = subject.new_file(file_path, file_content)

        expect(result.content).to eq(file_content)
      end

      it 'returns untransformed encoding' do
        result = subject.new_file(file_path, file_content, encoding: 'base64')

        expect(result.encoding).to eq('base64')
      end
    end

    context 'with lfs enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      it 'reuses cached gitattributes' do
        expect(repository.raw).to receive(:blob_at).with(branch_name, '.gitattributes').once

        subject.new_file(file_path, file_content)
        subject.new_file('another_file.lfs', file_content)
      end

      it "creates an LfsObject with the file's content" do
        subject.new_file(file_path, file_content)

        expect(LfsObject.last.file.read).to eq file_content
      end

      it 'returns an LFS pointer' do
        result = subject.new_file(file_path, file_content)

        expect(result.content).to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
      end

      it 'returns LFS pointer encoding as text' do
        result = subject.new_file(file_path, file_content, encoding: 'base64')

        expect(result.encoding).to eq('text')
      end

      context 'when an actual file is passed' do
        let(:file) { Tempfile.new(file_path) }

        before do
          file.write(file_content)
          file.rewind
        end

        after do
          file.unlink
        end

        it "creates an LfsObject with the file's content" do
          subject.new_file(file_path, file)

          expect(LfsObject.last.file.read).to eq file_content
        end

        context 'when repository is a design repository' do
          let(:file_path) { "/#{DesignManagement.designs_directory}/test_file.lfs" }
          let(:repository) { project.design_repository }

          it "creates an LfsObject with the file's content" do
            subject.new_file(file_path, file)

            expect(LfsObject.last.file.read).to eq(file_content)
          end

          it 'saves the correct repository_type to LfsObjectsProject' do
            subject.new_file(file_path, file)

            expect(project.lfs_objects_projects.first.repository_type).to eq('design')
          end
        end

        context 'when content type detection enabled' do
          let(:detect_content_type) { true }

          before do
            allow(Gitlab::Utils::MimeType).to receive(:from_string).with(file_content).and_return(mime_type)
          end

          context 'when mime type detected' do
            let(:mime_type) { 'image/tiff' }

            it 'creates a file with custom content type' do
              expect(CarrierWaveStringFile).to receive(:new_file).with({
                file_content: file_content,
                filename: anything,
                content_type: mime_type
              })

              subject.new_file(file_path, file, detect_content_type: detect_content_type)
            end
          end

          context 'when mime type not detected' do
            let(:mime_type) { nil }

            it 'creates a file with default content type' do
              expect(CarrierWaveStringFile).to receive(:new).with(file_content)

              subject.new_file(file_path, file, detect_content_type: detect_content_type)
            end
          end
        end
      end

      context "when doesn't use LFS" do
        let(:file_path) { 'other.filetype' }

        it "doesn't create LFS pointers" do
          new_content = subject.new_file(file_path, file_content).content

          expect(new_content).not_to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
          expect(new_content).to eq(file_content)
        end
      end

      it 'links LfsObjects to project' do
        expect do
          subject.new_file(file_path, file_content)
        end.to change { project.lfs_objects.count }.by(1)
      end

      it 'saves the repository_type to LfsObjectsProject' do
        subject.new_file(file_path, file_content)

        expect(project.lfs_objects_projects.first.repository_type).to eq('project')
      end

      context 'when LfsObject already exists' do
        let(:lfs_pointer) { Gitlab::Git::LfsPointerFile.new(file_content) }

        before do
          create(:lfs_object, oid: lfs_pointer.sha256, size: lfs_pointer.size)
        end

        it 'links LfsObjects to project' do
          expect do
            subject.new_file(file_path, file_content)
          end.to change { project.lfs_objects.count }.by(1)
        end
      end

      context 'when the LfsObject is already linked to project' do
        before do
          subject.new_file(file_path, file_content)
        end

        shared_examples 'a new LfsObject is not created' do
          it do
            expect do
              second_service.new_file(file_path, file_content)
            end.not_to change { project.lfs_objects.count }
          end
        end

        context 'and the service is called again with the same repository type' do
          let(:second_service) { described_class.new(project, repository, branch_name) }

          include_examples 'a new LfsObject is not created'

          it 'does not create a new LfsObjectsProject record' do
            expect do
              second_service.new_file(file_path, file_content)
            end.not_to change { project.lfs_objects_projects.count }
          end
        end

        context 'and the service is called again with a different repository type' do
          let(:second_service) { described_class.new(project, project.wiki.repository, branch_name) }

          before do
            expect(second_service).to receive(:lfs_file?).and_return(true)
          end

          include_examples 'a new LfsObject is not created'

          it 'creates a new LfsObjectsProject record' do
            expect do
              second_service.new_file(file_path, file_content)
            end.to change { project.lfs_objects_projects.count }.by(1)
          end

          it 'sets the correct repository_type on the new LfsObjectsProject record' do
            second_service.new_file(file_path, file_content)

            repository_types = project.lfs_objects_projects.order(:id).pluck(:repository_type)

            expect(repository_types).to eq(%w[project wiki])
          end
        end
      end

      # This can happen when uploading a file via the UI where it will create
      # a new branch when sitting on the default branch.
      context 'when start_branch_name is provided' do
        subject(:with_start_branch_name) do
          described_class.new(project, repository, branch_name, start_branch_name: start_branch_name)
        end

        context "and is the same as branch_name" do
          let(:start_branch_name) { branch_name }

          it 'stores the file as an LFS object' do
            with_start_branch_name.new_file(file_path, file_content)

            expect(LfsObject.last.file.read).to eq file_content
          end
        end

        context "when the branch doesn't yet exist" do
          let(:branch_name) { project.default_branch }
          let(:start_branch_name) { 'lfs' }

          it 'stores the file as an LFS object' do
            subject.new_file(file_path, file_content)
            expect(LfsObject.last.file.read).to eq file_content

            new_file_content = 'More test file content'
            with_start_branch_name.new_file('another_file.lfs', new_file_content)
            expect(LfsObject.last.file.read).to eq new_file_content
          end
        end
      end
    end
  end

  describe '#branch_to_base_off' do
    using RSpec::Parameterized::TableSyntax

    where(:start_branch_name, :branch_name, :expected_branch_to_base_off) do
      nil    | nil    | nil
      'main' | nil    | 'main'
      nil    | 'main' | 'main'
      'main' | 'main' | 'main'
      'new'  | 'main' | 'new'
      'old'  | 'new'  | 'old'
    end

    with_them do
      subject do
        described_class.new(project, repository, branch_name, start_branch_name: start_branch_name).branch_to_base_off
      end

      it { is_expected.to eq(expected_branch_to_base_off) }
    end
  end
end
