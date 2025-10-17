# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownEngines::GlfmMarkdown, feature_category: :markdown do
  it 'defaults to generating sourcepos' do
    engine = described_class.new({})
    expected = <<~TEXT
      <h1 data-sourcepos="1:1-1:4"><a href="#hi" aria-hidden="true" class="anchor" id="user-content-hi"></a>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off sourcepos' do
    engine = described_class.new({ no_sourcepos: true })
    expected = <<~TEXT
      <h1><a href="#hi" aria-hidden="true" class="anchor" id="user-content-hi"></a>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off header anchors' do
    engine = described_class.new({ no_header_anchors: true, no_sourcepos: true })
    expected = <<~TEXT
      <h1>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off autolinking' do
    engine = described_class.new({ autolink: false, no_sourcepos: true })
    expected = <<~TEXT
      <p>http://example.com</p>
    TEXT

    expect(engine.render('http://example.com')).to eq expected
  end

  it 'returns proper inline sourcepos' do
    engine = described_class.new({})
    expected = <<~TEXT
      <p data-sourcepos="1:1-1:6"><code data-sourcepos="1:1-1:6">code</code></p>
    TEXT

    expect(engine.render('`code`')).to eq expected
  end

  it 'turns on minimal markdown options' do
    engine = described_class.new({ minimum_markdown: true })
    expected = <<~TEXT
      <p><a href="http://example.com">http://example.com</a> <em>emphasis</em> $x + y$</p>
    TEXT

    expect(engine.render('http://example.com _emphasis_ $x + y$')).to eq expected
  end

  describe 'placeholder detection' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group_project) { create(:project, :in_group) }

    let(:project_reference) { project }

    shared_examples 'enables placeholder rendering by default' do
      it 'processes %{} syntax as placeholders' do
        engine = described_class.new({ project: project_reference, no_sourcepos: true })
        expected = <<~TEXT
          <p><span data-placeholder>%{test}</span></p>
        TEXT

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
      expected = <<~TEXT
        <p>%{test}</p>
      TEXT

      expect(engine.render('%{test}')).to eq expected
    end

    it 'turns off placeholder detection when :broadcast_message_placeholders' do
      engine = described_class.new({ broadcast_message_placeholders: true, project: project, no_sourcepos: true })
      expected = <<~TEXT
        <p>%{test}</p>
      TEXT

      expect(engine.render('%{test}')).to eq expected
    end

    it 'turns off placeholder detection when :markdown_placeholders disabled' do
      stub_feature_flags(markdown_placeholders: false)

      engine = described_class.new({ project: project, no_sourcepos: true })
      expected = <<~TEXT
        <p>%{test}</p>
      TEXT

      expect(engine.render('%{test}')).to eq expected
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
