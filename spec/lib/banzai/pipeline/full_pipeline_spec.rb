# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::FullPipeline, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

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
    let(:identifier) { html[/.*fnref-1-(\d+).*/, 1] }
    let(:footnote_markdown) do
      <<~EOF
        first[^1] and second[^😄second] and twenty[^_twenty]
        [^1]: one
        [^😄second]: two
        [^_twenty]: twenty
      EOF
    end

    let(:filtered_footnote) do
      <<~EOF.strip_heredoc
        <p dir="auto">first<sup class="footnote-ref"><a href="#fn-1-#{identifier}" id="fnref-1-#{identifier}" data-footnote-ref>1</a></sup> and second<sup class="footnote-ref"><a href="#fn-%F0%9F%98%84second-#{identifier}" id="fnref-%F0%9F%98%84second-#{identifier}" data-footnote-ref>2</a></sup> and twenty<sup class="footnote-ref"><a href="#fn-_twenty-#{identifier}" id="fnref-_twenty-#{identifier}" data-footnote-ref>3</a></sup></p>
        <section data-footnotes class="footnotes">
        <ol>
        <li id="fn-1-#{identifier}">
        <p>one <a href="#fnref-1-#{identifier}" data-footnote-backref aria-label="Back to content" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        <li id="fn-%F0%9F%98%84second-#{identifier}">
        <p>two <a href="#fnref-%F0%9F%98%84second-#{identifier}" data-footnote-backref aria-label="Back to content" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        <li id="fn-_twenty-#{identifier}">
        <p>twenty <a href="#fnref-_twenty-#{identifier}" data-footnote-backref aria-label="Back to content" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        </ol>
        </section>
      EOF
    end

    it 'properly adds the necessary ids and classes' do
      stub_commonmark_sourcepos_disabled

      expect(html.lines.map(&:strip).join("\n")).to eq filtered_footnote.strip
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

    shared_examples 'table of contents tag' do |tag, tag_html|
      let(:markdown) do
        <<-MARKDOWN.strip_heredoc
          #{tag}

          # Header
        MARKDOWN
      end

      let(:invalid_markdown) do
        <<-MARKDOWN.strip_heredoc
          test #{tag}

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

        expect(output).to include("test #{tag_html}")
      end
    end

    context 'with [[_TOC_]] as tag' do
      it_behaves_like 'table of contents tag', '[[_TOC_]]', '[[<em>TOC</em>]]'
    end

    context 'with [toc] as tag' do
      it_behaves_like 'table of contents tag', '[toc]', '[toc]'
      it_behaves_like 'table of contents tag', '[TOC]', '[TOC]'
    end
  end

  describe 'backslash escapes' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue)   { create(:issue, project: project) }

    it 'does not convert an escaped reference' do
      markdown = "\\#{issue.to_reference}"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("<span data-escaped-char>#</span>#{issue.iid}")
    end

    it 'converts user reference with escaped underscore because of italics' do
      markdown = '_@test\__'
      output = described_class.to_html(markdown, project: project)

      expect(output).to include('<em>@test_</em>')
    end

    context 'when a reference (such as a label name) is autocompleted with characters that require escaping' do
      # Labels are fairly representative of the type of characters that can be in a reference
      # and aligns with the testing in spec/frontend/gfm_auto_complete_spec.js
      where(:valid, :label_name, :markdown) do
        # These are currently not supported
        # true   | 'a~bug'      | '~"a\~bug"'
        # true   | 'b~~bug~~'   | '~"b\~\~bug\~\~"'

        true   | 'c_bug_'     | '~c_bug\_'
        true   | 'c_bug_'     | 'Label ~c_bug\_ and _more_ text'
        true   | 'd _bug_'    | '~"d \_bug\_"'
        true   | 'e*bug*'     | '~"e\*bug\*"'
        true   | 'f *bug*'    | '~"f \*bug\*"'
        true   | 'f *bug*'    | 'Label ~"f \*bug\*" **with** more text'
        true   | 'g`bug`'     | '~"g\`bug\`" '
        true   | 'h `bug`'    | '~"h \`bug\`"'
      end

      with_them do
        it 'detects valid escaped reference' do
          create(:label, name: label_name, project: project)

          result = Banzai::Pipeline::FullPipeline.call(markdown, project: project)

          expect(result[:output].css('a').first.attr('class')).to eq 'gfm gfm-label has-tooltip gl-link gl-label-link'
          expect(result[:output].css('a').first.content).to eq label_name
        end
      end
    end
  end

  describe 'cmark-gfm and autlolinks' do
    it 'does not hang with significant number of unclosed image links' do
      markdown = '![a ' * 300000

      expect do
        Timeout.timeout(2.seconds) { described_class.to_html(markdown, project: nil) }
      end.not_to raise_error
    end
  end
end
