# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PlainMarkdownPipeline do
  using RSpec::Parameterized::TableSyntax

  describe 'backslash escapes' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue)   { create(:issue, project: project) }

    def correct_html_included(markdown, expected)
      result = described_class.call(markdown, {})

      expect(result[:output].to_html).to include(expected)

      result
    end

    context 'when feature flag honor_escaped_markdown is disabled' do
      before do
        stub_feature_flags(honor_escaped_markdown: false)
      end

      it 'does not escape the markdown' do
        result = described_class.call(%q(\!), project: project)
        output = result[:output].to_html

        expect(output).to eq('<p data-sourcepos="1:1-1:2">!</p>')
        expect(result[:escaped_literals]).to be_falsey
      end
    end

    # Test strings taken from https://spec.commonmark.org/0.29/#backslash-escapes
    describe 'CommonMark tests', :aggregate_failures do
      it 'converts all ASCII punctuation to literals' do
        markdown = %q(\!\"\#\$\%\&\'\*\+\,\-\.\/\:\;\<\=\>\?\@\[\]\^\_\`\{\|\}\~) + %q[\(\)\\\\]
        punctuation = %w(! " # $ % &amp; ' * + , - . / : ; &lt; = &gt; ? @ [ \\ ] ^ _ ` { | } ~) + %w[( )]

        result = described_class.call(markdown, project: project)
        output = result[:output].to_html

        punctuation.each { |char| expect(output).to include("<span>#{char}</span>") }
        expect(result[:escaped_literals]).to be_truthy
      end

      it 'does not convert other characters to literals' do
        markdown = %q(\→\A\a\ \3\φ\«)
        expected = '\→\A\a\ \3\φ\«'

        result = correct_html_included(markdown, expected)
        expect(result[:escaped_literals]).to be_falsey
      end

      describe 'escaped characters are treated as regular characters and do not have their usual Markdown meanings' do
        where(:markdown, :expected) do
          %q(\*not emphasized*)              | %q(<span>*</span>not emphasized*)
          %q(\<br/> not a tag)               | %q(<span>&lt;</span>br/&gt; not a tag)
          %q!\[not a link](/foo)!            | %q!<span>[</span>not a link](/foo)!
          %q(\`not code`)                    | %q(<span>`</span>not code`)
          %q(1\. not a list)                 | %q(1<span>.</span> not a list)
          %q(\# not a heading)               | %q(<span>#</span> not a heading)
          %q(\[foo]: /url "not a reference") | %q(<span>[</span>foo]: /url "not a reference")
          %q(\&ouml; not a character entity) | %q(<span>&amp;</span>ouml; not a character entity)
        end

        with_them do
          it 'keeps them as literals' do
            correct_html_included(markdown, expected)
          end
        end
      end

      it 'backslash is itself escaped, the following character is not' do
        markdown = %q(\\\\*emphasis*)
        expected = %q(<span>\</span><em>emphasis</em>)

        correct_html_included(markdown, expected)
      end

      it 'backslash at the end of the line is a hard line break' do
        markdown = <<~MARKDOWN
          foo\\
          bar
        MARKDOWN
        expected = "foo<br>\nbar"

        correct_html_included(markdown, expected)
      end

      describe 'backslash escapes do not work in code blocks, code spans, autolinks, or raw HTML' do
        where(:markdown, :expected) do
          %q(`` \[\` ``)       | %q(<code>\[\`</code>)
          %q(    \[\])         | %Q(<code>\\[\\]\n</code>)
          %Q(~~~\n\\[\\]\n~~~) | %Q(<code>\\[\\]\n</code>)
          %q(<http://example.com?find=\*>) | %q(<a href="http://example.com?find=%5C*">http://example.com?find=\*</a>)
          %q[<a href="/bar\/)">]           | %q[<a href="/bar%5C/)">]
        end

        with_them do
          it { correct_html_included(markdown, expected) }
        end
      end

      describe 'work in all other contexts, including URLs and link titles, link references, and info strings in fenced code blocks' do
        where(:markdown, :expected) do
          %q![foo](/bar\* "ti\*tle")!            | %q(<a href="/bar*" title="ti*tle">foo</a>)
          %Q![foo]\n\n[foo]: /bar\\* "ti\\*tle"! | %q(<a href="/bar*" title="ti*tle">foo</a>)
          %Q(``` foo\\+bar\nfoo\n```)            | %Q(<code lang="foo+bar">foo\n</code>)
        end

        with_them do
          it { correct_html_included(markdown, expected) }
        end
      end
    end
  end
end
