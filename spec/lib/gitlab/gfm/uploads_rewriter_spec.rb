require 'spec_helper'

describe Gitlab::Gfm::UploadsRewriter do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project) }
  let(:rewriter) { described_class.new(text, old_project, user) }

  context 'text contains links to uploads' do
    let(:image_uploader) do
      build(:file_uploader, project: old_project)
    end

    let(:zip_uploader) do
      build(:file_uploader, project: old_project,
                            fixture: 'ci_build_artifacts.zip')
    end

    let(:text) do
      "Text and #{image_uploader.markdown_link} and #{zip_uploader.markdown_link}"
    end

    describe '#rewrite' do
      let!(:new_text) { rewriter.rewrite(new_project) }

      let(:old_files) { [image_uploader, zip_uploader].map(&:file) }
      let(:new_files) do
        described_class.new(new_text, new_project, user).files
      end

      let(:old_paths) { old_files.map(&:path) }
      let(:new_paths) { new_files.map(&:path) }

      it 'rewrites content' do
        expect(new_text).not_to eq text
        expect(new_text.length).to eq text.length
      end

      it 'copies files' do
        expect(new_files).to all(exist)
        expect(old_paths).not_to match_array new_paths
        expect(old_paths).to all(include(old_project.disk_path))
        expect(new_paths).to all(include(new_project.disk_path))
      end

      it 'does not remove old files' do
        expect(old_files).to all(exist)
      end

      it 'generates a new secret for each file' do
        expect(new_paths).not_to include image_uploader.secret
        expect(new_paths).not_to include zip_uploader.secret
      end
    end

    describe '#needs_rewrite?' do
      subject { rewriter.needs_rewrite? }
      it { is_expected.to eq true }
    end

    describe '#files' do
      subject { rewriter.files }
      it { is_expected.to be_an(Array) }
    end
  end
end
