require "spec_helper"

describe Lfs::FileTransformer do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:file_content) { 'Test file content' }
  let(:branch_name) { 'lfs' }
  let(:file_path) { 'test_file.lfs' }

  subject { described_class.new(project, branch_name) }

  describe '#new_file' do
    context 'with lfs disabled' do
      it 'skips gitattributes check' do
        expect(repository.raw).not_to receive(:blob_at)

        subject.new_file(file_path, file_content)
      end
    end

    context 'with lfs enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      it 'reuses cached gitattributes' do
        second_file = 'another_file.lfs'

        expect(repository.raw).to receive(:blob_at).with(branch_name, '.gitattributes').once

        subject.new_file(file_path, file_content)
        subject.new_file(second_file, file_content)
      end

      it "creates an LfsObject with the file's content" do
        subject.new_file(file_path, file_content)

        expect(LfsObject.last.file.read).to eq file_content
      end

      it 'creates an LFS pointer' do
        new_content = subject.new_file(file_path, file_content)

        expect(new_content).to start_with('version https://git-lfs.github.com/spec/v1')
      end

      context "when doesn't use LFS" do
        let(:file_path) { 'other.filetype' }

        it "doesn't create LFS pointers" do
          new_content = subject.new_file(file_path, file_content)

          expect(new_content).not_to start_with('version https://git-lfs.github.com/spec/v1')
          expect(new_content).to eq(file_content)
        end
      end

      it 'sets up after_transform! to link LfsObjects to project' do
        subject.new_file(file_path, file_content)

        expect { subject.after_transform! }.to change { project.lfs_objects.count }.by(1)
      end
    end
  end

  describe '.link_lfs_objects' do
    context 'with lfs enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'when given a block' do
        it 'links LfsObject to the project automatically' do
          expect do
            described_class.link_lfs_objects(project, branch_name) do |t|
              t.new_file(file_path, file_content)
            end
          end.to change { project.lfs_objects.count }.by(1)
        end

        it 'skips linking LfsObjects if the block returns falsey' do
          expect do
            described_class.link_lfs_objects(project, branch_name) do |t|
              t.new_file(file_path, file_content)
              false
            end
          end.not_to change { project.lfs_objects.count }
        end

        it 'returns the result of the block' do
          result = described_class.link_lfs_objects(project, branch_name) do |t|
            :dummy_commit
          end

          expect(result).to eq :dummy_commit
        end
      end
    end
  end
end
