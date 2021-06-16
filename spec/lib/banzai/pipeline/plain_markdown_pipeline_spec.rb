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

    describe 'CommonMark tests', :aggregate_failures do
      it 'converts all reference punctuation to literals' do
        reference_chars = Banzai::Filter::MarkdownPreEscapeFilter::REFERENCE_CHARACTERS
        markdown = reference_chars.split('').map {|char| char.prepend("\\") }.join
        punctuation = Banzai::Filter::MarkdownPreEscapeFilter::REFERENCE_CHARACTERS.split('')
        punctuation = punctuation.delete_if {|char| char == '&' }
        punctuation << '&amp;'

        result = described_class.call(markdown, project: project)
        output = result[:output].to_html

        punctuation.each { |char| expect(output).to include("<span>#{char}</span>") }
        expect(result[:escaped_literals]).to be_truthy
      end

      it 'ensure we handle all the GitLab reference characters' do
        reference_chars = ObjectSpace.each_object(Class).map do |klass|
          next unless klass.included_modules.include?(Referable)
          next unless klass.respond_to?(:reference_prefix)
          next unless klass.reference_prefix.length == 1

          klass.reference_prefix
        end.compact

        reference_chars.all? do |char|
          Banzai::Filter::MarkdownPreEscapeFilter::REFERENCE_CHARACTERS.include?(char)
        end
      end

      it 'does not convert non-reference punctuation to spans' do
        markdown = %q(\"\'\*\+\,\-\.\/\:\;\<\=\>\?\[\]\_\`\{\|\}) + %q[\(\)\\\\]

        result = described_class.call(markdown, project: project)
        output = result[:output].to_html

        expect(output).not_to include('<span>')
        expect(result[:escaped_literals]).to be_falsey
      end

      it 'does not convert other characters to literals' do
        markdown = %q(\→\A\a\ \3\φ\«)
        expected = '\→\A\a\ \3\φ\«'

        result = correct_html_included(markdown, expected)
        expect(result[:escaped_literals]).to be_falsey
      end

      describe 'backslash escapes do not work in code blocks, code spans, autolinks, or raw HTML' do
        where(:markdown, :expected) do
          %q(`` \@\! ``)       | %q(<code>\@\!</code>)
          %q(    \@\!)         | %Q(<code>\\@\\!\n</code>)
          %Q(~~~\n\\@\\!\n~~~) | %Q(<code>\\@\\!\n</code>)
          %q(<http://example.com?find=\@>) | %q(<a href="http://example.com?find=%5C@">http://example.com?find=\@</a>)
          %q[<a href="/bar\@)">]           | %q[<a href="/bar%5C@)">]
        end

        with_them do
          it { correct_html_included(markdown, expected) }
        end
      end

      describe 'work in all other contexts, including URLs and link titles, link references, and info strings in fenced code blocks' do
        where(:markdown, :expected) do
          %q![foo](/bar\@ "\@title")!            | %q(<a href="/bar@" title="@title">foo</a>)
          %Q![foo]\n\n[foo]: /bar\\@ "\\@title"! | %q(<a href="/bar@" title="@title">foo</a>)
          %Q(``` foo\\@bar\nfoo\n```)            | %Q(<code lang="foo@bar">foo\n</code>)
        end

        with_them do
          it { correct_html_included(markdown, expected) }
        end
      end
    end
  end
end
