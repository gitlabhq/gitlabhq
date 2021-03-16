# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::FullPipeline do
  describe 'References' do
    let(:project) { create(:project, :public) }
    let(:issue)   { create(:issue, project: project) }

    it 'handles markdown inside a reference' do
      markdown = "[some `code` inside](#{issue.to_reference})"
      result = described_class.call(markdown, project: project)
      link_content = result[:output].css('a').inner_html
      expect(link_content).to eq('some <code>code</code> inside')
    end

    it 'sanitizes reference HTML' do
      link_label = '<script>bad things</script>'
      markdown = "[#{link_label}](#{issue.to_reference})"
      result = described_class.to_html(markdown, project: project)
      expect(result).not_to include(link_label)
    end

    it 'escapes the data-original attribute on a reference' do
      markdown = %Q{[">bad things](#{issue.to_reference})}
      result = described_class.to_html(markdown, project: project)
      expect(result).to include(%{data-original='\"&amp;gt;bad things'})
    end
  end

  describe 'footnotes' do
    let(:project)    { create(:project, :public) }
    let(:html)       { described_class.to_html(footnote_markdown, project: project) }
    let(:identifier) { html[/.*fnref1-(\d+).*/, 1] }
    let(:footnote_markdown) do
      <<~EOF
        first[^1] and second[^second]
        [^1]: one
        [^second]: two
      EOF
    end

    let(:filtered_footnote) do
      <<~EOF
        <p dir="auto">first<sup class="footnote-ref"><a href="#fn1-#{identifier}" id="fnref1-#{identifier}">1</a></sup> and second<sup class="footnote-ref"><a href="#fn2-#{identifier}" id="fnref2-#{identifier}">2</a></sup></p>

        <section class="footnotes"><ol>
        <li id="fn1-#{identifier}">
        <p>one <a href="#fnref1-#{identifier}" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        <li id="fn2-#{identifier}">
        <p>two <a href="#fnref2-#{identifier}" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        </ol></section>
      EOF
    end

    it 'properly adds the necessary ids and classes' do
      stub_commonmark_sourcepos_disabled

      expect(html.lines.map(&:strip).join("\n")).to eq filtered_footnote
    end
  end

  describe 'links are detected as malicious' do
    it 'has tooltips for malicious links' do
      examples = %W[
        http://example.com/evil\u202E3pm.exe
        [evilexe.mp3](http://example.com/evil\u202E3pm.exe)
        rdar://localhost.com/\u202E3pm.exe
        http://one😄two.com
        [Evil-Test](http://one😄two.com)
        http://\u0261itlab.com
        [Evil-GitLab-link](http://\u0261itlab.com)
        ![Evil-GitLab-link](http://\u0261itlab.com.png)
      ]

      examples.each do |markdown|
        result = described_class.call(markdown, project: nil)[:output]
        link   = result.css('a').first

        expect(link[:class]).to include('has-tooltip')
      end
    end

    it 'has no tooltips for safe links' do
      examples = %w[
        http://example.com
        [Safe-Test](http://example.com)
        https://commons.wikimedia.org/wiki/File:اسكرام_2_-_تمنراست.jpg
        [Wikipedia-link](https://commons.wikimedia.org/wiki/File:اسكرام_2_-_تمنراست.jpg)
      ]

      examples.each do |markdown|
        result = described_class.call(markdown, project: nil)[:output]
        link   = result.css('a').first

        expect(link[:class]).to be_nil
      end
    end
  end

  describe 'table of contents' do
    let(:project) { create(:project, :public) }
    let(:markdown) do
      <<-MARKDOWN.strip_heredoc
          [[_TOC_]]

          # Header
      MARKDOWN
    end

    let(:invalid_markdown) do
      <<-MARKDOWN.strip_heredoc
          test [[_TOC_]]

          # Header
      MARKDOWN
    end

    it 'inserts a table of contents' do
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("<ul class=\"section-nav\">")
      expect(output).to include("<li><a href=\"#header\">Header</a></li>")
    end

    it 'does not insert a table of contents' do
      output = described_class.to_html(invalid_markdown, project: project)

      expect(output).to include("test [[<em>TOC</em>]]")
    end
  end

  describe 'backslash escapes' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue)   { create(:issue, project: project) }

    it 'does not convert an escaped reference' do
      markdown = "\\#{issue.to_reference}"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("<span>#</span>#{issue.iid}")
    end

    it 'converts user reference with escaped underscore because of italics' do
      markdown = '_@test\__'
      output = described_class.to_html(markdown, project: project)

      expect(output).to include('<em>@test_</em>')
    end
  end
end
