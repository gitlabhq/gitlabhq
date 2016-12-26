require 'spec_helper'

RSpec.describe WikiDirectory, models: true do
  describe 'validations' do
    subject { build(:wiki_directory) }

    it { is_expected.to validate_presence_of(:slug) }
  end

  describe '#initialize' do
    context 'when there are pages and directories' do
      let(:pages) { [build(:wiki_page)] }
      let(:other_directories) { [build(:wiki_directory)] }
      let(:directory) { WikiDirectory.new('/path_up_to/dir', pages, other_directories) }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute' do
        expect(directory.pages).to eq(pages)
      end

      it 'sets the directories attribute' do
        expect(directory.directories).to eq(other_directories)
      end
    end

    context 'when there are no pages or directories' do
      let(:directory) { WikiDirectory.new('/path_up_to/dir') }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute to an empty array' do
        expect(directory.pages).to eq([])
      end

      it 'sets the directories attribute to an empty array' do
        expect(directory.directories).to eq([])
      end
    end
  end
end
