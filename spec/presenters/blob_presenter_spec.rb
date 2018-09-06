require 'spec_helper'

describe BlobPresenter, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }

  let(:git_blob) do
    Gitlab::Git::Blob.find(
      repository,
      'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
      'files/ruby/regex.rb'
    )
  end

  let(:return_value) { double(:return_value) }

  describe '#highlight' do
    subject { described_class.new(blob) }

    let(:blob) { Blob.new(git_blob) }

    it 'returns highlighted content' do
      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: false, language: nil).and_return(return_value)
      expect(subject.highlight).to eq(return_value)
    end

    context 'with :plain' do
      it 'returns plain content when no_highlighting? is true' do
        allow(blob).to receive(:no_highlighting?).and_return(true)

        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: true, language: nil).and_return(return_value)
        expect(subject.highlight).to eq(return_value)
      end

      it 'returns plain content when :plain is true' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: true, language: nil).and_return(return_value)
        expect(subject.highlight(plain: true)).to eq(return_value)
      end

      it 'returns rich content when :plain is false, even when no_highlighting? is true' do
        allow(blob).to receive(:no_highlighting?).and_return(true)

        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: false, language: nil).and_return(return_value)
        expect(subject.highlight(plain: false)).to eq(return_value)
      end
    end

    context 'gitlab-language contains a match' do
      before do
        allow(blob).to receive(:language_from_gitattributes).and_return('ruby')
      end

      it 'passes language to inner call' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: false, language: 'ruby').and_return(return_value)
        expect(subject.highlight).to eq(return_value)
      end
    end
  end
end
