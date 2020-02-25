# frozen_string_literal: true

require 'spec_helper'

describe SnippetBlobPresenter do
  describe '#rich_data' do
    let(:snippet) { build(:personal_snippet) }

    subject { described_class.new(snippet.blob).rich_data }

    it 'returns nil when the snippet blob is binary' do
      allow(snippet.blob).to receive(:binary?).and_return(true)

      expect(subject).to be_nil
    end

    it 'returns markdown content when snippet file is markup' do
      snippet.file_name = 'test.md'
      snippet.content = '*foo*'

      expect(subject).to eq '<p data-sourcepos="1:1-1:5" dir="auto"><em>foo</em></p>'
    end

    it 'returns syntax highlighted content' do
      snippet.file_name = 'test.rb'
      snippet.content = 'class Foo;end'

      expect(subject)
        .to eq '<span id="LC1" class="line" lang="ruby"><span class="k">class</span> <span class="nc">Foo</span><span class="p">;</span><span class="k">end</span></span>'
    end

    it 'returns plain text highlighted content' do
      snippet.file_name = 'test'
      snippet.content = 'foo'

      expect(subject).to eq '<span id="LC1" class="line" lang="plaintext">foo</span>'
    end
  end

  describe '#plain_data' do
    let(:snippet) { build(:personal_snippet) }

    subject { described_class.new(snippet.blob).plain_data }

    it 'returns nil when the snippet blob is binary' do
      allow(snippet.blob).to receive(:binary?).and_return(true)

      expect(subject).to be_nil
    end

    it 'returns plain content when snippet file is markup' do
      snippet.file_name = 'test.md'
      snippet.content = '*foo*'

      expect(subject).to eq '<span id="LC1" class="line" lang="markdown"><span class="ge">*foo*</span></span>'
    end

    it 'returns plain syntax content' do
      snippet.file_name = 'test.rb'
      snippet.content = 'class Foo;end'

      expect(subject)
        .to eq '<span id="LC1" class="line" lang="">class Foo;end</span>'
    end

    it 'returns plain text highlighted content' do
      snippet.file_name = 'test'
      snippet.content = 'foo'

      expect(subject).to eq '<span id="LC1" class="line" lang="">foo</span>'
    end
  end

  describe '#raw_path' do
    subject { described_class.new(snippet.blob).raw_path }

    context 'with ProjectSnippet' do
      let!(:project) { create(:project) }
      let(:snippet) { create(:project_snippet, project: project) }

      it 'returns the raw path' do
        expect(subject).to eq "/#{snippet.project.full_path}/snippets/#{snippet.id}/raw"
      end
    end

    context 'with PersonalSnippet' do
      let(:snippet) { create(:personal_snippet) }

      it 'returns the raw path' do
        expect(subject).to eq "/snippets/#{snippet.id}/raw"
      end
    end
  end
end
