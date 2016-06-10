require 'spec_helper'

describe Gitlab::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
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
  end

  describe 'custom highlighting from .gitattributes' do
    let(:blob) { project.blob_at_branch('master', 'custom-highlighting/test.gitlab-custom') }
    let(:highlighter) {
      Gitlab::Highlight.new(blob.path, blob.contents, repository: project.repository)
    }

    it 'highlights as ruby' do
      expect(highlighter.lexer).to be_an_instance_of Rouge::Lexers::Ruby
    end
  end
end
