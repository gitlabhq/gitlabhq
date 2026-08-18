# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownEngines::GlfmMarkdown, feature_category: :markdown do
  describe 'header rendering' do
    it 'renders header with anchor by default' do
      engine = described_class.new({})
      html = engine.render('# Hello')

      fragment = Nokogiri::HTML.fragment(html)
      h1 = fragment.css('h1').first

      expect(h1['id']).to eq('user-content-hello')
      expect(h1['data-sourcepos']).to eq('1:1-1:7')
      expect(h1.css('a.anchor').first['href']).to eq('#hello')
      expect(h1.css('a.anchor').first['aria-label']).to eq("Link to heading 'Hello'")
      expect(h1.css('a.anchor').first['data-heading-content']).to eq('Hello')
    end

    it 'turns off header anchors' do
      engine = described_class.new({ no_header_anchors: true, no_sourcepos: true })
      expected = <<~HTML
        <h1>hi</h1>
      HTML

      expect(engine.render('# hi')).to eq expected
    end

    describe 'file prefix' do
      describe 'when different file paths produce slug collision' do
        using RSpec::Parameterized::TableSyntax

        where(:requested_path, :markdown) do
          'file.md'         | '## 1. Overview'
          'file-1.md'       | '## Overview'
          'file-1.markdown' | '## Overview'
          'file-1.mdown'    | '## Overview'
          'file-1.mkd'      | '## Overview'
          'file-1.mkdn'     | '## Overview'
        end

        with_them do
          it 'allows slug collision from different file and heading combinations' do
            engine = described_class.new(
              use_filename_in_anchor: true, requested_path: requested_path, no_sourcepos: true
            )
            html = engine.render(markdown)
            fragment = Nokogiri::HTML.fragment(html)

            expect(fragment.at_css('h2')['id']).to eq('user-content-file-1-overview')
            expect(fragment.at_css('h2 a.anchor')['href']).to eq('#file-1-overview')
          end
        end
      end

      describe 'when heading slugs should not be prefixed' do
        using RSpec::Parameterized::TableSyntax

        where(:context, :case_name) do
          { requested_path: '!#$%&*+,./:;=?@\^`|~<>[]{}().md',
            use_filename_in_anchor: true } | 'when slug would be empty'
          { requested_path: 'docs/CONTRIBUTING.md' } | 'when use_filename_in_anchor is not set'
          { use_filename_in_anchor: true }           | 'when requested_path is absent'
        end

        with_them do
          it 'generates heading IDs without file prefix' do
            engine = described_class.new({ no_sourcepos: true }.merge(context))
            html = engine.render('## CoC')
            fragment = Nokogiri::HTML.fragment(html)

            expect(fragment.at_css('h2')['id']).to eq('user-content-coc')
            expect(fragment.at_css('h2 a.anchor')['href']).to eq('#coc')
          end
        end
      end
    end
  end

  it 'turns off autolinking' do
    engine = described_class.new({ autolink: false, no_sourcepos: true })
    expected = <<~HTML
      <p>http://example.com</p>
    HTML

    expect(engine.render('http://example.com')).to eq expected
  end

  describe 'sourcepos' do
    it 'turns off sourcepos' do
      engine = described_class.new({ no_sourcepos: true })
      html = engine.render('# hi')

      fragment = Nokogiri::HTML.fragment(html)
      expect(fragment.css('h1').first['data-sourcepos']).to be_nil
    end

    it 'returns proper inline sourcepos' do
      engine = described_class.new({})
      expected = <<~HTML
        <p data-sourcepos="1:1-1:6"><code data-sourcepos="1:1-1:6">code</code></p>
      HTML

      expect(engine.render('`code`')).to eq expected
    end
  end

  describe 'placeholder detection' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group_project) { create(:project, :in_group) }

    let(:project_reference) { project }

    shared_examples 'enables placeholder rendering by default' do
      it 'processes %{} syntax as placeholders' do
        engine = described_class.new({ project: project_reference, no_sourcepos: true })
        expected = <<~HTML
          <p><span data-placeholder>%{test}</span></p>
        HTML

        expect(engine.render('%{test}')).to eq expected
      end
    end

    it_behaves_like 'enables placeholder rendering by default'

    context 'when project is project namespace' do
      let(:project_reference) { group_project.project_namespace }

      it_behaves_like 'enables placeholder rendering by default'
    end

    it 'turns off placeholder detection when :disable_placeholders' do
      engine = described_class.new({ disable_placeholders: true, project: project, no_sourcepos: true })
      expected = <<~HTML
        <p>%{test}</p>
      HTML

      expect(engine.render('%{test}')).to eq expected
    end

    it 'turns off placeholder detection when :broadcast_message_placeholders' do
      engine = described_class.new({ broadcast_message_placeholders: true, project: project, no_sourcepos: true })
      expected = <<~HTML
        <p>%{test}</p>
      HTML

      expect(engine.render('%{test}')).to eq expected
    end

    it 'turns off placeholder detection when :markdown_placeholders disabled' do
      stub_feature_flags(markdown_placeholders: false)

      engine = described_class.new({ project: project, no_sourcepos: true })
      expected = <<~HTML
        <p>%{test}</p>
      HTML

      expect(engine.render('%{test}')).to eq expected
    end
  end

  describe 'input encoding' do
    let(:engine) { described_class.new({ no_sourcepos: true }) }

    it 'renders UTF-8 input' do
      expect(engine.render('hello')).to include('hello')
    end

    it 'renders US-ASCII input' do
      text = 'hello'.encode(Encoding::US_ASCII)
      expect(engine.render(text)).to include('hello')
    end

    it 'renders Shift_JIS input' do
      text = 'こんにちは'.encode(Encoding::Shift_JIS)
      expect(engine.render(text)).to include('こんにちは')
    end

    it 'raises on invalid encoding' do
      text = (+"\xFF\xFE").force_encoding(Encoding::Shift_JIS)
      expect { engine.render(text) }.to raise_error(Encoding::InvalidByteSequenceError)
    end
  end

  describe 'escaped reference chars' do
    # In order to allow a user to short-circuit our reference shortcuts
    # (such as # or !), the user should be able to escape them, like \#.
    # The parser surrounds characters that were escaped in the source document
    # with `<span data-escaped-char>...</span>`, such that our reference
    # filters won't catch them.
    #
    # The list of characters to have such treatment is defined as
    # Banzai::Filter::GlfmMarkdown::REFERENCE_CHARS, which is passed into
    # ::GLFMMarkdown.to_html.
    it 'ensure we handle all the GitLab reference characters', :eager_load do
      reference_chars = ObjectSpace.each_object(Class).filter_map do |klass|
        next unless klass.included_modules.include?(Referable)
        next unless klass.respond_to?(:reference_prefix)
        next unless klass.reference_prefix.length == 1

        klass.reference_prefix
      end.compact

      expect(Banzai::Filter::MarkdownEngines::GlfmMarkdown::REFERENCE_CHARS).to include(*reference_chars)
    end

    it 'keeps reference chars escaped with <span data-escaped-char>' do
      engine = described_class.new({ no_sourcepos: true })
      markdown = Banzai::Filter::MarkdownEngines::GlfmMarkdown::REFERENCE_CHARS.map { |char| "\\#{char}" }.join(' ')
      html = engine.render(markdown)

      Banzai::Filter::MarkdownEngines::GlfmMarkdown::REFERENCE_CHARS.each do |item|
        char = item == '&' ? '&amp;' : item

        expect(html).to include("<span data-escaped-char>#{char}</span>")
      end
    end

    it 'does not include <span data-escaped-char> for non-reference punctuation' do
      engine = described_class.new({ no_sourcepos: true })

      # rubocop:disable Style/StringConcatenation -- better format for escaping characters
      markdown = %q(\"\'\*\+\,\-\.\/\;\<\=\>\?\[\]\`\|) + %q[\(\)\\\\]
      # rubocop:enable Style/StringConcatenation

      html = engine.render(markdown)

      expect(html).not_to include('<span data-escaped-char')
    end

    it 'keeps html escaped text' do
      engine = described_class.new({})
      markdown = '[link](<foo\>)'
      html = engine.render(markdown)

      expect(html).to eq "<p data-sourcepos=\"1:1-1:14\">[link](&lt;foo&gt;)</p>\n"
    end

    it 'handles emphasis in CJK text correctly' do
      engine = described_class.new({})
      markdown = '**わ〜い！強調記号ができます！**問題なし！'
      html = engine.render(markdown)

      expect(html).to eq("<p data-sourcepos=\"1:1-1:61\"><strong data-sourcepos=\"1:1-1:46\">" \
        "わ〜い！強調記号ができます！</strong>問題なし！</p>\n")
    end
  end
end
