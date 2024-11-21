# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gfm::UploadsRewriter, feature_category: :shared do
  let(:user) { create(:user) }
  let(:rewriter) { described_class.new(+text, nil, source_container, user) }

  RSpec.shared_examples 'rewrites text contains links to uploads' do
    let(:image_uploader) { build(:file_uploader, container: source_container) }
    let(:zip_uploader) { build(:file_uploader, container: source_container, fixture: 'ci_build_artifacts.zip') }

    let(:text) do
      "Text and #{image_uploader.markdown_link} and #{zip_uploader.markdown_link}".freeze
    end

    def referenced_files(text, container)
      scanner = FileUploader::MARKDOWN_PATTERN.scan(text)
      referenced_files = scanner.map do |match|
        UploaderFinder.new(container, match[0], match[1]).execute
      end

      referenced_files.compact.select(&:exists?)
    end

    shared_examples 'files are accessible' do
      describe '#rewrite' do
        subject(:rewrite) { new_text }

        let(:new_text) { rewriter.rewrite(target_container) }

        let(:old_files) { [image_uploader, zip_uploader] }
        let(:new_files) do
          referenced_files(new_text, target_container)
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
          expect(old_paths).to all(include(source_uploader_class.model_path_segment(source_container)))
          expect(new_paths).to all(include(target_uploader_class.model_path_segment(target_container)))
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
          allow_next_instance_of(source_uploader_class) do |file|
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
      text = "#{plain_image_link} and #{embedded_link}"

      moved_text = described_class.new(text, nil, source_container, user).rewrite(target_container)

      expect(moved_text.scan(/!\[.*?\]/).count).to eq(1)
      expect(moved_text.scan(/\A\[.*?\]/).count).to eq(1)
    end

    it 'does not cause a timeout on pathological text' do
      text = '[!l' * 30000

      Timeout.timeout(3) do
        moved_text = described_class.new(text, nil, source_container, user).rewrite(target_container)

        expect(moved_text).to eq(text)
      end
    end

    context 'file are stored locally' do
      include_examples 'files are accessible'
    end

    context 'files are stored remotely' do
      before do
        stub_uploads_object_storage(source_uploader_class)

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

  context 'with various containers' do
    let_it_be(:project_uploader_class) { FileUploader }
    let_it_be(:group_uploader_class) { NamespaceFileUploader }
    let_it_be(:source_project) { create(:project) }
    let_it_be(:target_project) { create(:project) }
    let_it_be(:source_group) { create(:group) }
    let_it_be(:target_group) { create(:group) }

    context 'when source and target are projects' do
      let(:source_container) { source_project }
      let(:target_container) { target_project }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source and target are project namespaces' do
      let(:source_container) { source_project.project_namespace }
      let(:target_container) { target_project.project_namespace }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source and target are groups' do
      let(:source_container) { source_group }
      let(:target_container) { target_group }
      let(:source_uploader_class) { group_uploader_class }
      let(:target_uploader_class) { group_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a project and target is a project namespace' do
      let(:source_container) { source_project }
      let(:target_container) { target_project.project_namespace }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a project and target is a group' do
      let(:source_container) { source_project }
      let(:target_container) { target_group }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { group_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a project namespace and target is a project' do
      let(:source_container) { source_project.project_namespace }
      let(:target_container) { target_project }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a project namespace and target is a group' do
      let(:source_container) { source_project.project_namespace }
      let(:target_container) { target_group }
      let(:source_uploader_class) { project_uploader_class }
      let(:target_uploader_class) { group_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a group and target is a project' do
      let(:source_container) { source_group }
      let(:target_container) { target_project }
      let(:source_uploader_class) { group_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end

    context 'when source is a group and target is a project namespace' do
      let(:source_container) { source_group }
      let(:target_container) { target_project.project_namespace }
      let(:source_uploader_class) { group_uploader_class }
      let(:target_uploader_class) { project_uploader_class }

      it_behaves_like 'rewrites text contains links to uploads'
    end
  end
end
