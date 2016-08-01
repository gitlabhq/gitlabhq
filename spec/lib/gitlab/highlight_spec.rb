require 'spec_helper'

describe Gitlab::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }

  describe '.highlight_lines' do
    let(:lines) do
      Gitlab::Highlight.highlight_lines(project.repository, commit.id, 'files/ruby/popen.rb')
    end

    it 'should properly highlight all the lines' do
      expect(lines[4]).to eq(%Q{<span id="LC5" class="line">  <span class="kp">extend</span> <span class="nb">self</span></span>\n})
      expect(lines[21]).to eq(%Q{<span id="LC22" class="line">    <span class="k">unless</span> <span class="no">File</span><span class="p">.</span><span class="nf">directory?</span><span class="p">(</span><span class="n">path</span><span class="p">)</span></span>\n})
      expect(lines[26]).to eq(%Q{<span id="LC27" class="line">    <span class="vi">@cmd_status</span> <span class="o">=</span> <span class="mi">0</span></span>\n})
    end

    describe 'with CRLF' do
      let(:branch) { 'crlf-diff' }
      let(:blob) { repository.blob_at_branch(branch, path) }
      let(:lines) do
        Gitlab::Highlight.highlight_lines(project.repository, 'crlf-diff', 'files/whitespace')
      end

      it 'strips extra LFs' do
        expect(lines[0]).to eq("<span id=\"LC1\" class=\"line\">test  </span>")
      end
    end
  end

  describe 'custom highlighting from .gitattributes' do
    let(:branch) { 'gitattributes' }
    let(:blob) { repository.blob_at_branch(branch, path) }

    let(:highlighter) do
      Gitlab::Highlight.new(blob.path, blob.data, repository: repository)
    end

    before { project.change_head('gitattributes') }

    describe 'basic language selection' do
      let(:path) { 'custom-highlighting/test.gitlab-custom' }
      it 'highlights as ruby' do
        expect(highlighter.lexer.tag).to eq 'ruby'
      end
    end

    describe 'cgi options' do
      let(:path) { 'custom-highlighting/test.gitlab-cgi' }

      it 'highlights as json with erb' do
        expect(highlighter.lexer.tag).to eq 'erb'
        expect(highlighter.lexer.parent.tag).to eq 'json'
      end
    end
  end
end
