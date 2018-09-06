require 'spec_helper'

describe Gitlab::Highlight do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe 'language provided' do
    let(:highlighter) do
      described_class.new('foo.erb', 'bar', language: 'erb?parent=json')
    end

    it 'sets correct lexer' do
      expect(highlighter.lexer.tag).to eq 'erb'
      expect(highlighter.lexer.parent.tag).to eq 'json'
    end
  end

  describe '#highlight' do
    describe 'with CRLF' do
      let(:branch) { 'crlf-diff' }
      let(:path) { 'files/whitespace' }
      let(:blob) { repository.blob_at_branch(branch, path) }
      let(:lines) do
        described_class.highlight(blob.path, blob.data).lines
      end

      it 'strips extra LFs' do
        expect(lines[0]).to eq("<span id=\"LC1\" class=\"line\" lang=\"plaintext\">test  </span>")
      end
    end

    it 'links dependencies via DependencyLinker' do
      expect(Gitlab::DependencyLinker).to receive(:link)
        .with('file.name', 'Contents', anything).and_call_original

      described_class.highlight('file.name', 'Contents')
    end
  end
end
