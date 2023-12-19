# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tree, feature_category: :source_code_management do
  subject(:tree) { described_class.new(repository, '54fcc214') }

  let_it_be(:repository) { create(:project, :repository).repository }

  describe '#readme' do
    subject { tree.readme }

    before do
      allow(tree).to receive(:blobs).and_return(files)
    end

    context 'when repository does not contains a README file' do
      let(:files) { [fake_blob('file'), fake_blob('license'), fake_blob('copying')] }

      it { is_expected.to be_nil }
    end

    context 'when repository does not contains a previewable README file' do
      let(:files) { [fake_blob('file'), fake_blob('README.pages'), fake_blob('README.png')] }

      it { is_expected.to be_nil }
    end

    context 'when repository contains a previewable README file' do
      let(:files) { [fake_blob('README.png'), fake_blob('README'), fake_blob('file')] }

      it { is_expected.to have_attributes(name: 'README') }
    end

    context 'when repository contains more than one README file' do
      let(:files) { [fake_blob('file'), fake_blob('README.md'), fake_blob('README.asciidoc')] }

      it 'returns first previewable README' do
        is_expected.to have_attributes(name: 'README.md')
      end

      context 'when only plain-text READMEs' do
        let(:files) { [fake_blob('file'), fake_blob('README'), fake_blob('README.txt')] }

        it 'returns first plain text README' do
          is_expected.to have_attributes(name: 'README')
        end
      end
    end

    context 'when the repository has a previewable and plain text READMEs' do
      let(:files) { [fake_blob('file'), fake_blob('README'), fake_blob('README.md')] }

      it 'prefers previewable README file' do
        is_expected.to have_attributes(name: 'README.md')
      end
    end
  end

  describe '#cursor' do
    subject { tree.cursor }

    it { is_expected.to be_an_instance_of(Gitaly::PaginationCursor) }
  end

  private

  def fake_blob(name)
    instance_double(Gitlab::Git::Blob, name: name)
  end
end
