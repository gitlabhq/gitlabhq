# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PlainMarkdownPipeline, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  # TODO: This is legacy code, and is only used with the Ruby parser.
  # The current markdown parser now handles adding data-escaped-char.
  # The Ruby parser is now only for benchmarking purposes.
  # issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
  describe 'legacy backslash handling', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue)   { create(:issue, project: project) }
    let_it_be(:context) do
      {
        project: project,
        no_sourcepos: true,
        markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE
      }
    end

    it 'converts all escapable punctuation to literals' do
      markdown = Banzai::Filter::MarkdownPreEscapeLegacyFilter::ESCAPABLE_CHARS.pluck(:escaped).join

      result = described_class.call(markdown, context)
      output = result[:output].to_html

      Banzai::Filter::MarkdownPreEscapeLegacyFilter::ESCAPABLE_CHARS.each do |item|
        char = item[:char] == '&' ? '&amp;' : item[:char]

        if item[:reference]
          expect(output).to include("<span data-escaped-char>#{char}</span>")
        else
          expect(output).not_to include("<span data-escaped-char>#{char}</span>")
          expect(output).to include(char)
        end
      end

      expect(result[:escaped_literals]).to be_truthy
    end

    it 'ensure we handle all the GitLab reference characters', :eager_load do
      reference_chars = ObjectSpace.each_object(Class).map do |klass|
        next unless klass.included_modules.include?(Referable)
        next unless klass.respond_to?(:reference_prefix)
        next unless klass.reference_prefix.length == 1

        klass.reference_prefix
      end.compact

      reference_chars.all? do |char|
        Banzai::Filter::MarkdownPreEscapeLegacyFilter::TARGET_CHARS.include?(char)
      end
    end

    it 'does not convert non-reference/latex punctuation to spans' do
      markdown = %q(\"\'\*\+\,\-\.\/\:\;\<\=\>\?\[\]\`\|) + %q[\(\)\\\\]

      result = described_class.call(markdown, context)
      output = result[:output].to_html

      expect(output).not_to include('<span')
      expect(result[:escaped_literals]).to be_falsey
    end

    it 'does not convert other characters to literals' do
      markdown = %q(\→\A\a\ \3\φ\«)
      expected = '\→\A\a\ \3\φ\«'

      result = correct_html_included(markdown, expected, context)
      expect(result[:escaped_literals]).to be_falsey
    end

    describe 'backslash escapes are untouched in code blocks, code spans, autolinks, or raw HTML' do
      where(:markdown, :expected) do
        %q(`` \@\! ``)                   | %q(<code>\@\!</code>)
        %q(    \@\!)                     | %(<code>\\@\\!\n</code>)
        %(~~~\n\\@\\!\n~~~)              | %(<code>\\@\\!\n</code>)
        %q($1+\$2$)                      | %q(<code data-math-style="inline">1+\\$2</code>)
        %q(<http://example.com?find=\@>) | %q(<a href="http://example.com?find=%5C@">http://example.com?find=\@</a>)
        %q[<a href="/bar\@)">]           | %q[<a href="/bar\@)">]
      end

      with_them do
        it { correct_html_included(markdown, expected, context) }
      end
    end

    describe 'work in all other contexts, including URLs and link titles, link references, and info strings in fenced code blocks' do
      let(:markdown) { %(``` foo\\@bar\nfoo\n```) }

      it 'renders correct html' do
        correct_html_included(markdown, %(<pre lang="foo@bar"><code>foo\n</code></pre>), context)
      end

      where(:markdown, :expected) do
        %q![foo](/bar\@ "\@title")! | %q(<a href="/bar@" title="@title">foo</a>)
        %([foo]\n\n[foo]: /bar\\@ "\\@title") | %q(<a href="/bar@" title="@title">foo</a>)
      end

      with_them do
        it { correct_html_included(markdown, expected, context) }
      end
    end

    it 'does not have a polynomial regex' do
      markdown = "x \\#\n\n#{'mliteralcmliteral-' * 450000}mliteral"

      expect do
        Timeout.timeout(2.seconds) { described_class.to_html(markdown, project: project) }
      end.not_to raise_error
    end
  end

  def correct_html_included(markdown, expected, context = {})
    result = described_class.call(markdown, context)

    expect(result[:output].to_html).to include(expected)

    result
  end
end
