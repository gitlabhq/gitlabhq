require 'spec_helper'

describe Gitlab::Gfm::UploadsRewriter do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project) }
  let(:rewriter) { described_class.new(text, old_project, user) }

  context 'text contains links to uploads' do
    let(:path) { Rails.root + 'spec/fixtures/rails_sample.jpg' }
    let(:file) { fixture_file_upload(path, 'image/jpg') }
    let(:uploader) { FileUploader.new(old_project) }
    let!(:store) { uploader.store!(file) } # TODO, see #xxx (carrierwave issue)
    let(:markdown) { uploader.to_h[:markdown] }
    let(:text) { "Text and #{markdown}"}

    describe '#rewrite' do
      let!(:new_text) { rewriter.rewrite(new_project) }
      let(:new_rewriter) { described_class.new(new_text, new_project, user) }
      let(:old_file) { rewriter.files.first }
      let(:new_file) { new_rewriter.files.first }

      it 'rewrites content' do
        expect(new_text).to_not eq text
        expect(new_text.length).to eq text.length
      end

      it 'copies files' do
        expect(new_file.exists?).to eq true
        expect(old_file.path).to_not eq new_file.path
        expect(new_file.path).to include new_project.path_with_namespace
      end

      it 'does not remove old files' do
        expect(old_file.exists?).to be true
      end
    end

    describe '#has_uploads?' do
      subject { rewriter.has_uploads? }
      it { is_expected.to eq true }
    end

    describe '#files' do
      subject { rewriter.files }
      it { is_expected.to be_an(Array) }
    end
  end
end
