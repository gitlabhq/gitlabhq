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
      expected = %Q[<span id="LC1" class="line" lang="common_lisp"><span class="p">(</span><span class="nb">make-pathname</span> <span class="ss">:defaults</span> <span class="nv">name</span></span>
<span id="LC2" class="line" lang="common_lisp"><span class="ss">:type</span> <span class="s">"assem"</span><span class="p">)</span></span>]

      expect(described_class.highlight(file_name, content)).to eq(expected)
    end

    it 'returns plain version for unknown lexer context' do
      result = described_class.highlight(plain_text_file_name, plain_text_content)

      expect(result).to eq(%[<span id="LC1" class="line" lang="plaintext">plain text contents</span>])
    end

    context 'when content is too long to be highlighted' do
      let(:result) { described_class.highlight(file_name, content) } # content is 44 bytes

      before do
        stub_feature_flags(one_megabyte_file_size_limit: false)
        stub_config(extra: { 'maximum_text_highlight_size_kilobytes' => 0.0001 } ) # 1.024 bytes
      end

      it 'confirm file size is 1MB when `one_megabyte_file_size_limit` is enabled' do
        stub_feature_flags(one_megabyte_file_size_limit: true)
        expect(described_class.too_large?(1024.kilobytes)).to eq(false)
        expect(described_class.too_large?(1025.kilobytes)).to eq(true)
      end

      it 'increments the metric for oversized files' do
        expect { result }.to change { over_highlight_size_limit('file size: 0.0001') }.by(1)
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
      let(:content) { "+aaa\n+bbb\n- ccc\n ddd\n"}
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
        .with('file.name', 'Contents', anything).and_call_original

      described_class.highlight('file.name', 'Contents')
    end

    context 'timeout' do
      subject { described_class.new('file.name', 'Contents') }

      it 'utilizes timeout for web' do
        expect(Timeout).to receive(:timeout).with(described_class::TIMEOUT_FOREGROUND).and_call_original

        subject.highlight("Content")
      end

      it 'utilizes longer timeout for sidekiq' do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        expect(Timeout).to receive(:timeout).with(described_class::TIMEOUT_BACKGROUND).and_call_original

        subject.highlight("Content")
      end
    end

    describe 'highlight timeouts' do
      let(:result) { described_class.highlight(file_name, content, language: "ruby") }

      context 'when there is an attempt' do
        it "increments the attempt counter with a defined language" do
          expect { result }.to change { highlight_attempt_total("ruby") }
        end

        it "increments the attempt counter with an undefined language" do
          expect do
            described_class.highlight(file_name, content)
          end.to change { highlight_attempt_total("undefined") }
        end
      end

      context 'when there is a timeout error while highlighting' do
        before do
          allow(Timeout).to receive(:timeout).twice.and_raise(Timeout::Error)
          # This is done twice because it's rescued first and then
          # calls the original exception
        end

        it "increments the foreground counter if it's in the foreground" do
          expect { result }
            .to raise_error(Timeout::Error)
            .and change { highlight_timeout_total('foreground') }.by(1)
            .and not_change { highlight_timeout_total('background') }
        end

        it "increments the background counter if it's in the background" do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)

          expect { result }
            .to raise_error(Timeout::Error)
            .and change { highlight_timeout_total('background') }.by(1)
            .and not_change { highlight_timeout_total('foreground') }
        end
      end
    end
  end

  def highlight_timeout_total(source)
    Gitlab::Metrics
      .counter(:highlight_timeout, 'Counts the times highlights have timed out')
      .get(source: source)
  end

  def highlight_attempt_total(source)
    Gitlab::Metrics
      .counter(:file_highlighting_attempt, 'Counts the times highlighting has been attempted on a file')
      .get(source: source)
  end

  def over_highlight_size_limit(source)
    Gitlab::Metrics
      .counter(:over_highlight_size_limit,
               'Count the times text has been over the highlight size limit')
      .get(source: source)
  end
end
