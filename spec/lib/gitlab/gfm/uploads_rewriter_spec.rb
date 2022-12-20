# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gfm::UploadsRewriter do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project) }
  let(:rewriter) { described_class.new(+text, nil, old_project, user) }

  context 'text contains links to uploads' do
    let(:image_uploader) do
      build(:file_uploader, project: old_project)
    end

    let(:zip_uploader) do
      build(:file_uploader, project: old_project,
                            fixture: 'ci_build_artifacts.zip')
    end

    let(:text) do
      "Text and #{image_uploader.markdown_link} and #{zip_uploader.markdown_link}".freeze # rubocop:disable Style/RedundantFreeze
    end

    def referenced_files(text, project)
      scanner = FileUploader::MARKDOWN_PATTERN.scan(text)
      referenced_files = scanner.map do |match|
        UploaderFinder.new(project, match[0], match[1]).execute
      end

      referenced_files.compact.select(&:exists?)
    end

    shared_examples 'files are accessible' do
      describe '#rewrite' do
        subject(:rewrite) { new_text }

        let(:new_text) { rewriter.rewrite(new_project) }

        let(:old_files) { [image_uploader, zip_uploader] }
        let(:new_files) do
          referenced_files(new_text, new_project)
        end

        let(:old_paths) { old_files.map(&:path) }
        let(:new_paths) { new_files.map(&:path) }

        it 'rewrites content' do
          rewrite

          expect(new_text).not_to eq text
          expect(new_text.length).to eq text.length
        end

        it 'copies files' do
          rewrite

          expect(new_files).to all(exist)
          expect(old_paths).not_to match_array new_paths
          expect(old_paths).to all(include(old_project.disk_path))
          expect(new_paths).to all(include(new_project.disk_path))
        end

        it 'does not remove old files' do
          rewrite

          expect(old_files).to all(exist)
        end

        it 'generates a new secret for each file' do
          rewrite

          expect(new_paths).not_to include image_uploader.secret
          expect(new_paths).not_to include zip_uploader.secret
        end

        it 'skips nil files do' do
          allow_next_instance_of(UploaderFinder) do |finder|
            allow(finder).to receive(:execute).and_return(nil)
          end

          rewrite

          expect(new_files).to be_empty
          expect(new_text).to eq(text)
        end

        it 'skips non-existant files' do
          allow_next_instance_of(FileUploader) do |file|
            allow(file).to receive(:exists?).and_return(false)
          end

          rewrite

          expect(new_files).to be_empty
          expect(new_text).to eq(text)
        end
      end
    end

    it 'does not rewrite plain links as embedded' do
      embedded_link = image_uploader.markdown_link
      plain_image_link = embedded_link.delete_prefix('!')
      text = +"#{plain_image_link} and #{embedded_link}"

      moved_text = described_class.new(text, nil, old_project, user).rewrite(new_project)

      expect(moved_text.scan(/!\[.*?\]/).count).to eq(1)
      expect(moved_text.scan(/\A\[.*?\]/).count).to eq(1)
    end

    it 'does not casue a timeout on pathological text' do
      text = '[!l' * 30000

      Timeout.timeout(3) do
        moved_text = described_class.new(text, nil, old_project, user).rewrite(new_project)

        expect(moved_text).to eq(text)
      end
    end

    context 'file are stored locally' do
      include_examples 'files are accessible'
    end

    context 'files are stored remotely' do
      before do
        stub_uploads_object_storage(FileUploader)

        old_files.each do |file|
          file.migrate!(ObjectStorage::Store::REMOTE)
        end
      end

      include_examples 'files are accessible'
    end

    describe '#needs_rewrite?' do
      subject { rewriter.needs_rewrite? }

      it { is_expected.to eq true }
    end
  end
end
