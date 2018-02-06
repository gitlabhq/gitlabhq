require 'spec_helper'

RSpec.describe WikiDirectory do
  describe 'validations' do
    subject { build(:wiki_directory) }

    it { is_expected.to validate_presence_of(:slug) }
  end

  describe '#initialize' do
    context 'when there are pages' do
      let(:pages) { [build(:wiki_page)] }
      let(:directory) { described_class.new('/path_up_to/dir', pages) }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute' do
        expect(directory.pages).to eq(pages)
      end
    end

    context 'when there are no pages' do
      let(:directory) { described_class.new('/path_up_to/dir') }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute to an empty array' do
        expect(directory.pages).to eq([])
      end
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      directory = build(:wiki_directory)

      expect(directory.to_partial_path).to eq('projects/wikis/wiki_directory')
    end
  end
end
