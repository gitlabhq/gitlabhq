# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::FullPipeline, feature_category: :markdown do
  include RepoHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue)   { create(:issue, project: project) }

  it_behaves_like 'sanitize pipeline'

  describe 'References' do
    before do
      stub_commonmark_sourcepos_disabled
    end

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

    it 'prevents xss by not replacing the same reference in one anchor multiple times' do
      reference_link = ::Gitlab::UrlBuilder.instance.issue_url(issue)
      markdown = <<~TEXT
        <div>
        <a href="#{reference_link}<i>
        <a alt='&quot;#{reference_link}'></a>
        </i>">#{reference_link}<i>
        <a alt='"#{reference_link}'></a></i></a>
        </div>
      TEXT

      markdown.delete!("\n")

      # Part of understanding this spec means knowing how the above is actually treated
      # by the FullPipeline.  The PlainMarkdownPipeline runs first and produces the DOM
      # which is actually operated on by the GfmPipeline.
      #
      # We used to use an HTML4-based parser which would parse these nested <a> tags and
      # leave them nested, opening the door to the vulnerability this spec was written to
      # cover. We now use an HTML5 parser, which correctly keeps them separate at this
      # early stage
      # (https://dev.w3.org/html5/spec-LC/tree-construction.html#:~:text=adoption%20agency%20algorithm),
      # closing the door to this kind of vulnerability entirely.
      #
      # Here we recreate the PlainMarkdownPipeline's effects by themselves and assert the
      # result, to clarify how the malicious input is now interpreted.
      html_after_plain_markdown_pipeline = Banzai::Pipeline::PlainMarkdownPipeline.to_html(markdown, project:)
      expect(html_after_plain_markdown_pipeline).to eq_html(<<-HTML, trim_text_nodes: true)
        <div>
          <a href="#{reference_link}&lt;i&gt;&lt;a alt='&quot;#{reference_link}'&gt;&lt;/a&gt;&lt;/i&gt;">
            #{reference_link}
            <i></i>
          </a>
          <i>
            <a alt="&quot;#{reference_link}"></a>
          </i>
        </div>
      HTML

      # The vulnerability relied on the href's content (which includes a spelled-out "<a>" tag)
      # being equal to its inner HTML. Now, the previously nested <a> is not located within it
      # in the DOM, so this cannot happen.

      # As above, we assert the full result to clarify its exact structure. We used to interpret
      # this input as a valid reference link, which eventually lead to the original XSS whose
      # fix this spec initially accompanied. As of the HTML5 parser, the nested <a>s no longer
      # make it to the DOM nested, so the first one cannot be interpreted as a reference link under
      # any circumstances.
      result = described_class.to_html(markdown, project: project)
      expect(result).to eq_html(<<-HTML, trim_text_nodes: true)
        <div>
          <a href="#{reference_link}&lt;i&gt;&lt;a%20alt='%22#{reference_link}'&gt;&lt;/a&gt;&lt;/i&gt;"
             rel="nofollow noreferrer noopener" target="_blank">
            #{reference_link}
            <i></i>
          </a>
          <i>
            <a alt="&quot;#{reference_link}"></a>
          </i>
        </div>
      HTML
    end

    it 'escapes the data-original attribute on a reference' do
      markdown = %{[">bad things](#{issue.to_reference})}
      doc = described_class.call(markdown, project: project)[:output]
      link = doc.at_css('a.gfm')

      expect(link['data-original']).to eq(%("&gt;bad things))
    end
  end

  describe 'footnotes' do
    let(:doc)        { described_class.call(footnote_markdown, project: project)[:output] }
    let(:identifier) { doc.to_html[/fnref-1-(\d+)/, 1] }
    let(:footnote_markdown) do
      <<~EOF
        first[^1] and second[^😄second] and twenty[^_twenty]
        [^1]: one
        [^😄second]: two
        [^_twenty]: twenty
      EOF
    end

    it 'properly adds the necessary ids and classes' do
      stub_commonmark_sourcepos_disabled

      footnote_refs = doc.css('a[data-footnote-ref]')
      expect(footnote_refs.count).to eq(3)
      expect(footnote_refs[0]['href']).to eq("#fn-1-#{identifier}")
      expect(footnote_refs[1]['href']).to eq("#fn-%F0%9F%98%84second-#{identifier}")
      expect(footnote_refs[2]['href']).to eq("#fn-_twenty-#{identifier}")

      section = doc.at_css('section[data-footnotes]')
      expect(section).to be_present
      expect(section['class']).to eq('footnotes')

      backrefs = section.css('a[data-footnote-backref]')
      expect(backrefs.count).to eq(3)
      expect(backrefs[0]['data-footnote-backref-idx']).to eq('1')
      expect(backrefs[1]['data-footnote-backref-idx']).to eq('2')
      expect(backrefs[2]['data-footnote-backref-idx']).to eq('3')
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
        stub_commonmark_sourcepos_disabled

        output = described_class.to_html(invalid_markdown, project: project)

        expect(output).to include("test #{tag_html}")
      end
    end

    context 'with [[_TOC_]] as tag' do
      it_behaves_like 'table of contents tag', '[[_TOC_]]', '<a href="_TOC_" data-wikilink="true">_TOC_</a>'
    end

    context 'with [toc] as tag' do
      it_behaves_like 'table of contents tag', '[toc]', '[toc]'
      it_behaves_like 'table of contents tag', '[TOC]', '[TOC]'
    end
  end

  describe 'backslash escapes' do
    it 'does not convert an escaped reference' do
      stub_commonmark_sourcepos_disabled

      markdown = "\\#{issue.to_reference}"
      doc = described_class.call(markdown, project: project)[:output]

      escaped_span = doc.at_css('span[data-escaped-char]')

      expect(escaped_span).to be_present
      expect(escaped_span.text).to eq('#')
      expect(doc.text).to eq("##{issue.iid}")
    end

    it 'converts user reference with escaped underscore because of italics' do
      stub_commonmark_sourcepos_disabled

      markdown = '_@test\__'
      doc = described_class.call(markdown, project: project)[:output]

      em = doc.at_css('em')
      expect(em).to be_present
      expect(em.text).to eq('@test_')
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

  context 'when input is malicious' do
    let_it_be(:markdown1) { '![a ' * 3 }
    let_it_be(:markdown2) { "$1$\n" * 190000 }
    let_it_be(:markdown3) { "[^1]\n[^1]:\n" * 100000 }
    let_it_be(:markdown4) { "[](a)" * 190000 }
    let_it_be(:markdown5) { "|x|x|x|x|x|\n-|-|-|-|-|\n|a|\n|a|\n|a|\n" * 6900 }
    let_it_be(:markdown6) { "`a^2+b^2=c^2` + " * 56000 }
    let_it_be(:markdown7) { ':y: ' * 190000 }
    let_it_be(:markdown8) { '<img>' * 100000 }

    where(:payload, :markdown) do
      "'![a ' * 3"                                        | ref(:markdown1)
      '"$1$\n" * 190000'                                  | ref(:markdown2)
      '"[^1]\n[^1]:\n" * 100000'                          | ref(:markdown3)
      '"[](a)" * 190000'                                  | ref(:markdown4)
      '"|x|x|x|x|x|\n-|-|-|-|-|\n|a|\n|a|\n|a|\n" * 6900' | ref(:markdown5)
      '"`a^2+b^2=c^2` + " * 56000'                        | ref(:markdown5)
      "':y: ' * 190000"                                   | ref(:markdown7)
      "'<img>' * 100000"                                  | ref(:markdown8)
    end

    with_them do
      it 'is not long running' do
        expect do
          Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { described_class.to_html(markdown, project: nil) }
        end.not_to raise_error
      end
    end
  end

  describe 'when using include in code segements' do
    let_it_be(:ref)            { 'markdown' }
    let_it_be(:requested_path) { '/' }
    let_it_be(:commit)         { project.commit(ref) }
    let_it_be(:context) do
      {
        commit: commit,
        project: project,
        ref: ref,
        text_source: :blob,
        requested_path: requested_path,
        no_sourcepos: true
      }
    end

    let_it_be(:project_files) do
      {
        'diagram.puml' => "@startuml\nBob -> Sara : Hello\n@enduml",
        'code.yaml' => "---\ntest: true"
      }
    end

    let(:input) do
      <<~MD
        ```plantuml
        ::include{file=diagram.puml}
        ```
        ```yaml
        ::include{file=code.yaml}
        ```
      MD
    end

    around do |example|
      create_and_delete_files(project, project_files, branch_name: ref) do
        example.run
      end
    end

    subject(:output) { described_class.call(input, context)[:output].to_html }

    it 'renders PlanUML' do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")

      is_expected.to include 'http://localhost:8080/png/U9npA2v9B2efpStXSifFKj2rKmXEB4fKi5BmICt9oUToICrB0Se10EdD34a0'
    end

    it 'renders code' do
      is_expected.to include 'language-yaml'
      is_expected.to include '<span class="na">test</span>'
      is_expected.to include '<span class="kc">true</span>'
    end
  end

  describe 'math does not get rendered as link' do
    [
      "$[(a+b)c](d+e)$",
      '$$[(a+b)c](d+e)$$',
      '$`[(a+b)c](d+e)`$'
    ].each do |input|
      it "when using '#{input}' as input" do
        result = described_class.call(input, project: nil)[:output]
        expect(result.css('a').first).to be_nil
      end
    end
  end

  describe 'inline block-level raw HTML in list items' do
    it 'does not let an inline <div> in a list item swallow the rest of the document' do
      markdown = "1. first <div>\n2. second <div>\n\nAfter the list.\n"
      result = described_class.call(markdown, project: nil)
      doc = result[:output]

      paragraph = doc.css('p').find { |p| p.text.include?('After the list') }
      expect(paragraph).to be_present
      expect(paragraph.ancestors.map(&:name)).not_to include('ol')
    end

    it 'does not let an inline <section> in a list item swallow the rest of the document' do
      markdown = "1. first <section>\n2. second <section>\n\nAfter the list.\n"
      result = described_class.call(markdown, project: nil)
      doc = result[:output]

      paragraph = doc.css('p').find { |p| p.text.include?('After the list') }
      expect(paragraph).to be_present
      expect(paragraph.ancestors.map(&:name)).not_to include('ol')
    end
  end

  describe 'SVG foreign content XSS prevention' do
    # The HTML5 parser creates namespaced attributes (e.g. xlink:href) inside
    # SVG foreign content.  These can shadow same-named HTML attributes and
    # cause Nokogiri's remove_attribute to remove the wrong one, letting a
    # javascript: URL survive sanitisation.
    #
    # BaseSanitizationFilter strips namespaced attributes so that
    # SanitizeLinkFilter can then remove the dangerous href normally.

    it 'strips javascript: href from an SVG anchor with xlink:href' do
      result = described_class.to_html(
        '<svg><a href="javascript:alert(1)" xlink:href="x">click</a></svg>',
        project: nil
      )

      doc = Nokogiri::HTML5.fragment(result)
      anchor = doc.at_css('a')

      expect(anchor).to be_present
      expect(anchor['href']).to be_nil
      expect(anchor.text).to eq('click')
    end

    it 'strips javascript: href from a MathML-nested SVG anchor with xlink:href' do
      result = described_class.to_html(
        '<math><annotation-xml encoding="application/xhtml+xml">' \
          '<svg><a href="javascript:alert(1)" xlink:href="x">click</a></svg>' \
          '</annotation-xml></math>',
        project: nil
      )

      doc = Nokogiri::HTML5.fragment(result)
      anchor = doc.at_css('a')

      expect(anchor['href']).to be_nil
    end

    it 'preserves safe hrefs on SVG anchors after namespace stripping' do
      result = described_class.to_html(
        '<svg><a href="https://example.com" xlink:href="x">click</a></svg>',
        project: nil
      )

      doc = Nokogiri::HTML5.fragment(result)
      anchor = doc.at_css('a')

      expect(anchor).to be_present
      expect(anchor['href']).to eq('https://example.com')
    end
  end

  describe 'pathological input' do
    it 'returns an error message for deeply nested emphasis when run in a thread' do
      thread = Thread.start do
        n = 5000
        markdown = ("*a **a " * n) + (" a** a*" * n)

        rendered = described_class.to_html(markdown, project: nil)

        expect(rendered).to include('nesting was too deep')
      end
      thread.join
    end
  end
end
