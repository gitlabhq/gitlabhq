# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Highlight do
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
    let(:plain_text_file_name) { "test.txt" }
    let(:plain_text_content) { "plain text contents" }
    let(:file_name) { 'test.lisp' }
    let(:content) { "(make-pathname :defaults name\n:type \"assem\")" }
    let(:multiline_content) do
      %q(
      def test(input):
        """This is line 1 of a multi-line comment.
        This is line 2.
        """
      )
    end

    it 'highlights' do
      expected = %[<span id="LC1" class="line" lang="common_lisp"><span class="p">(</span><span class="nb">make-pathname</span> <span class="ss">:defaults</span> <span class="nv">name</span></span>
<span id="LC2" class="line" lang="common_lisp"><span class="ss">:type</span> <span class="s">"assem"</span><span class="p">)</span></span>]

      expect(described_class.highlight(file_name, content)).to eq(expected)
    end

    it 'returns plain version for unknown lexer context' do
      result = described_class.highlight(plain_text_file_name, plain_text_content)

      expect(result).to eq(%(<span id="LC1" class="line" lang="plaintext">plain text contents</span>))
    end

    context 'when content is too long to be highlighted' do
      let(:result) { described_class.highlight(file_name, content) } # content is 44 bytes

      before do
        stub_config(extra: { 'maximum_text_highlight_size_kilobytes' => 0.0001 }) # 1.024 bytes
      end

      it 'returns plain version for long content' do
        expect(result).to eq(%[<span id="LC1" class="line" lang="">(make-pathname :defaults name</span>\n<span id="LC2" class="line" lang="">:type "assem")</span>])
      end
    end

    it 'highlights multi-line comments' do
      result = described_class.highlight(file_name, multiline_content)
      html = Nokogiri::HTML(result)
      lines = html.search('.s')

      expect(lines.count).to eq(3)
      expect(lines[0].text).to eq('"""This is line 1 of a multi-line comment.')
      expect(lines[1].text).to eq('        This is line 2.')
      expect(lines[2].text).to eq('        """')
    end

    context 'diff highlighting' do
      let(:file_name) { 'test.diff' }
      let(:content) { "+aaa\n+bbb\n- ccc\n ddd\n" }
      let(:expected) do
        %q(<span id="LC1" class="line" lang="diff"><span class="gi">+aaa</span></span>
<span id="LC2" class="line" lang="diff"><span class="gi">+bbb</span></span>
<span id="LC3" class="line" lang="diff"><span class="gd">- ccc</span></span>
<span id="LC4" class="line" lang="diff"> ddd</span>)
      end

      it 'highlights each line properly' do
        result = described_class.highlight(file_name, content)

        expect(result).to eq(expected)
      end

      context 'when start line number is set' do
        let(:expected) do
          %q(<span id="LC10" class="line" lang="diff"><span class="gi">+aaa</span></span>
<span id="LC11" class="line" lang="diff"><span class="gi">+bbb</span></span>
<span id="LC12" class="line" lang="diff"><span class="gd">- ccc</span></span>
<span id="LC13" class="line" lang="diff"> ddd</span>)
        end

        it 'highlights each line properly' do
          result = described_class.new(file_name, content).highlight(content, context: { line_number: 10 })

          expect(result).to eq(expected)
        end
      end
    end

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
        .with('file.name', 'Contents', anything, used_on: :blob).and_call_original

      described_class.highlight('file.name', 'Contents')
    end

    context 'timeout' do
      subject(:highlight) { described_class.new('file.rb', 'begin', language: 'ruby').highlight('Content') }

      it 'falls back to plaintext on timeout' do
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        expect(Gitlab::RenderTimeout).to receive(:timeout).and_raise(Timeout::Error)

        expect(Rouge::Lexers::PlainText).to receive(:lex).and_call_original

        highlight
      end
    end

    it 'increments usage counter', :prometheus do
      described_class.highlight(file_name, content)

      gitlab_highlight_usage_counter = Gitlab::Metrics.registry.get(:gitlab_highlight_usage)

      expect(gitlab_highlight_usage_counter.get(used_on: :blob)).to eq(1)
      expect(gitlab_highlight_usage_counter.get(used_on: :diff)).to eq(0)
    end

    context 'when used_on is specified' do
      it 'increments usage counter', :prometheus do
        described_class.highlight(file_name, content, used_on: :diff)

        gitlab_highlight_usage_counter = Gitlab::Metrics.registry.get(:gitlab_highlight_usage)

        expect(gitlab_highlight_usage_counter.get(used_on: :diff)).to eq(1)
        expect(gitlab_highlight_usage_counter.get(used_on: :blob)).to eq(0)
      end

      it 'links dependencies via DependencyLinker' do
        expect(Gitlab::DependencyLinker).to receive(:link)
          .with(file_name, content, anything, used_on: :diff).and_call_original

        described_class.highlight(file_name, content, used_on: :diff)
      end
    end
  end
end
