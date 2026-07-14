# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OtherMarkup, :aggregate_failures, feature_category: :wiki do
  let(:context) { {} }

  context 'when org-mode content' do
    let(:file_name) { 'unimportant_name.org' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML5.fragment(rendered) }
    let(:pre) { doc.css('pre').first }

    context 'with headings' do
      let(:input) do
        <<~ORG
          * Heading 1
          ** Heading 2
          *** Heading 3
          **** Heading 4
          ***** Heading 5
          ****** Heading 6
          ** Another H2
        ORG
      end

      it 'adds heading IDs and anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        expect(headings.size).to eq(7)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h1')['id']).to eq('user-content-heading-1')
        expect(doc.at_css('h1 a.anchor')['href']).to eq('#heading-1')
        expect(doc.at_css('h6')['id']).to eq('user-content-heading-6')
        expect(doc.at_css('h6 a.anchor')['href']).to eq('#heading-6')
      end
    end

    context 'with checkboxes' do
      let(:input) do
        <<~ORG
          - [-] Prepare release [50%]
            - [X] Update changelog
            - [ ] Review merge requests
        ORG
      end

      it 'renders nested mixed-state checkboxes' do
        inputs = doc.css('li.task-list-item input.task-list-item-checkbox')
        expect(inputs.size).to eq 3

        # [-]: indeterminate parent
        expect(inputs[0].has_attribute?('checked')).to be false
        expect(inputs[0]['data-indeterminate']).to eq 'true'

        # [X]: uppercase checked child
        expect(inputs[1].has_attribute?('checked')).to be true

        # [ ]: unchecked child
        expect(inputs[2].has_attribute?('checked')).to be false
        expect(inputs[2]['data-indeterminate']).to be_nil

        lis = doc.css('li.task-list-item')
        expect(lis.size).to eq 3

        # nested <ul> also gets task-list class
        uls = doc.css('ul.task-list')
        expect(uls.size).to eq 2
      end
    end

    context 'with auto-linking' do
      let(:input) { 'See https://example.com for details.' }

      it 'auto-links bare URLs' do
        link = doc.at_css('a')

        expect(link[:href]).to eq('https://example.com')
        expect(link[:rel]).to eq('nofollow noreferrer noopener')
        expect(link[:target]).to eq('_blank')
        expect(link.text).to eq('https://example.com')
      end
    end

    context 'with a source code block' do
      let(:input) do
        <<~ORG
          #+begin_src ruby
          def hello
            puts "world"
          end
          #+end_src
        ORG
      end

      it 'applies the canonical language attribute' do
        expect(pre['data-canonical-lang']).to eq('ruby')
      end
    end

    context 'with a PlantUML block' do
      before do
        Gitlab::CurrentSettings.current_application_settings.update!(
          plantuml_enabled: true,
          plantuml_url: 'https://plantuml.com/plantuml'
        )
      end

      let(:input) do
        <<~ORG
          #+begin_src plantuml
          Bob -> Alice: hello
          Alice -> Bob: hi
          #+end_src
        ORG
      end

      let(:expected_img) do
        <<~HTML.chomp
          <img class="plantuml" src="https://plantuml.com/plantuml/png/U9npoazIqBLJSCp9J4wrKiX8pSd9vm9pGA9E-Kb0iKm0o4SAt000" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IEFsaWNlOiBoZWxsbwpBbGljZSAtPiBCb2I6IGhp">
        HTML
      end

      it 'generates the PlantUML diagram' do
        expect(rendered).to include(expected_img)
      end
    end

    context 'with a Mermaid block' do
      let(:input) do
        <<~ORG
          #+begin_src mermaid
          graph TD;
              A-->B;
              A-->C;
              B-->D;
              C-->D;
          #+end_src
        ORG
      end

      it 'renders mermaid diagrams' do
        expect(pre['data-canonical-lang']).to eq('mermaid')
        expect(pre.at_css('code')[:class]).to include('js-render-mermaid')
      end
    end

    context 'with a math block' do
      let(:input) do
        <<~ORG
          #+begin_src math
          \\sqrt{2}
          #+end_src
        ORG
      end

      it 'renders math source blocks' do
        expect(pre['data-canonical-lang']).to eq('math')
        expect(pre['data-math-style']).to eq('display')
        expect(pre[:class]).to include('js-render-math')
      end
    end
  end

  context 'when restructured text' do
    let(:file_name) { 'unimportant_name.rst' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML5.fragment(rendered) }
    let(:pre) { doc.css('pre').first }

    context 'with headings' do
      let(:input) do
        <<~RST
          Heading 1
          =========

          Text.

          Heading 2
          ---------

          Text.

          Heading 3
          ~~~~~~~~~

          Text.

          Heading 4
          ^^^^^^^^^

          Text.

          Heading 5
          '''''''''

          Text.

          Heading 6
          """""""""

          Text.

          Another H2
          ----------
        RST
      end

      it 'adds heading IDs and anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        expect(headings.size).to eq(7)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h1')['id']).to eq('user-content-heading-1')
        expect(doc.at_css('h1 a.anchor')['href']).to eq('#heading-1')
        expect(doc.at_css('h6')['id']).to eq('user-content-heading-6')
        expect(doc.at_css('h6 a.anchor')['href']).to eq('#heading-6')
      end
    end

    context 'with contents directive' do
      let(:input) do
        <<~RST
          .. contents::

          Heading A
          =========

          Text.

          Heading B
          ---------

          Text.

          Heading C
          ~~~~~~~~~

          Text.

          Heading D
          ^^^^^^^^^

          Text.

          Heading E
          '''''''''

          Text.

          Another Heading B
          -----------------
        RST
      end

      it 'adds heading IDs and anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        expect(headings.size).to eq(6)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h2')['id']).to eq('user-content-heading-a')
        expect(doc.at_css('h2 a.anchor')['href']).to eq('#heading-a')
        expect(doc.at_css('h6')['id']).to eq('user-content-heading-e')
        expect(doc.at_css('h6 a.anchor')['href']).to eq('#heading-e')
      end
    end

    context 'with headings without body text' do
      let(:input) do
        <<~RST
          日本語の見出し 甲
          ===============

          日本語の見出し 乙
          ---------------

          日本語の見出し 丙
          ~~~~~~~~~~~~~~~

          日本語の見出し 丁
          ^^^^^^^^^^^^^^^
        RST
      end

      it 'preserves existing heading IDs generated by sectsubtitle_xform' do
        headings = doc.css('h1, h2')

        expect(headings.size).to eq(4)

        expect(headings[0]['id']).to eq('user-content-日本語の見出し-甲')
        expect(headings[0].at_css('a.anchor')['href']).to eq('#日本語の見出し-甲')

        # "id2" (docutils sequential id via sectsubtitle_xform) is preserved,
        # not slug from text
        expect(headings[1]['id']).to eq('user-content-id2')
        expect(headings[1].at_css('a.anchor')['href']).to eq('#id2')

        expect(headings[2]['id']).to eq('user-content-日本語の見出し-丙')
        expect(headings[2].at_css('a.anchor')['href']).to eq('#日本語の見出し-丙')

        # "id4" (docutils sequential id via sectsubtitle_xform) is preserved,
        # not slug from text
        expect(headings[3]['id']).to eq('user-content-id4')
        expect(headings[3].at_css('a.anchor')['href']).to eq('#id4')
      end
    end

    context 'when PlantUML is enabled' do
      let(:input) do
        <<~RST
          .. plantuml::
                 :caption: Caption with **bold** and *italic*

                 Bob -> Alice: hello
                 Alice -> Bob: hi
        RST
      end

      it 'generates the diagram' do
        Gitlab::CurrentSettings.current_application_settings.update!(plantuml_enabled: true, plantuml_url: 'https://plantuml.com/plantuml')

        output = <<~HTML
          <img class="plantuml" src="https://plantuml.com/plantuml/png/U9npoazIqBLJSCp9J4wrKiX8pSd9vm9pGA9E-Kb0iKm0o4SAt000" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IEFsaWNlOiBoZWxsbwpBbGljZSAtPiBCb2I6IGhp">
          <p>Caption with <strong>bold</strong> and <em>italic</em></p>
        HTML

        expect(rendered).to include(output.strip)
      end
    end

    context 'with a mermaid block' do
      let(:input) do
        <<~RST
          .. code:: mermaid

             graph TD;
                 A-->B;
                 A-->C;
                 B-->D;
                 C-->D;
        RST
      end

      it 'renders mermaid diagrams' do
        expect(pre['data-canonical-lang']).to eq('mermaid')
        expect(pre.at_css('code')[:class]).to include('js-render-mermaid')
      end
    end

    context 'with a math block' do
      let(:input) do
        <<~RST
          .. code:: math

             \\sqrt{2}
        RST
      end

      it 'renders math source blocks' do
        expect(pre['data-canonical-lang']).to eq('math')
        expect(pre['data-math-style']).to eq('display')
        expect(pre[:class]).to include('js-render-math')
      end
    end
  end

  context 'when rdoc content' do
    let(:file_name) { 'file.rdoc' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML5.fragment(rendered) }

    context 'with headings' do
      let(:input) do
        <<~RDOC
          = Heading 1

          == Heading 2

          === Heading 3

          ==== Heading 4

          ===== Heading 5

          ====== Heading 6

          == Another H2
        RDOC
      end

      it 'preserves existing heading IDs and adds anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        expect(headings.size).to eq(7)

        # RDoc generates heading IDs with a `label-` prefix.
        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-label-')
          expect(heading.at_css('a.anchor')['href']).to start_with('#label-')
        end
      end
    end
  end

  context 'XSS Checks' do
    links = {
      'links' => {
        file: 'file.rdoc',
        input: 'XSS[JaVaScriPt:alert(1)]',
        output: "\n" + '<p><a>XSS</a></p>' + "\n"
      }
    }
    links.each do |name, data|
      it "does not convert dangerous #{name} into HTML" do
        expect(render(data[:file], data[:input], context)).to eq(data[:output])
      end
    end
  end

  context 'when mediawiki content' do
    let(:file_name) { 'file.mediawiki' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML5.fragment(rendered) }

    context 'with headings' do
      let(:input) do
        <<~MEDIAWIKI
          = Heading 1 =

          == Heading 2 ==

          === Heading 3 ===

          ==== Heading 4 ====

          ===== Heading 5 =====

          ====== Heading 6 ======

          == Another H2 ==
        MEDIAWIKI
      end

      it 'adds heading IDs and anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        # WikiCloth renders an auto-generated table of contents with <h2>Table of Contents</h2>,
        # so the total is 7 content headings + 1 TOC heading = 8
        expect(headings.size).to eq(8)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h1')['id']).to eq('user-content-heading-1')
        expect(doc.at_css('h1 a.anchor')['href']).to eq('#heading-1')
        expect(doc.at_css('h6')['id']).to eq('user-content-heading-6')
        expect(doc.at_css('h6 a.anchor')['href']).to eq('#heading-6')
      end
    end

    context 'with <source> tags' do
      let(:file_name) { 'file.mediawiki' }

      shared_examples 'renders as preformatted escaped text' do |lang:|
        it 'does not raise and HTML-escapes content', :aggregate_failures do
          tag = lang ? %(<source lang="#{lang}">) : '<source>'
          input = "#{tag}a < b && c > d</source>"
          result = nil
          expect { result = render(file_name, input, context) }.not_to raise_error
          expect(result).to include('<pre>a &lt; b &amp;&amp; c &gt; d</pre>')
        end
      end

      context 'with a known language' do
        it_behaves_like 'renders as preformatted escaped text', lang: 'ruby'
      end

      context 'with an unknown language' do
        it_behaves_like 'renders as preformatted escaped text', lang: 'bash'
      end

      context 'with an empty language' do
        it_behaves_like 'renders as preformatted escaped text', lang: ''
      end

      context 'with no language specified' do
        it_behaves_like 'renders as preformatted escaped text', lang: nil
      end
    end
  end

  context 'when rendering takes too long' do
    let_it_be(:project, freeze: false) { create(:project, :repository) }

    let(:file_name) { 'foo.bar' }
    let(:context) { { project: project } }
    let(:text) { +'Noël' }

    before do
      stub_const('Gitlab::OtherMarkup::RENDER_TIMEOUT', 0.1)
      allow(GitHub::Markup).to receive(:render) do
        sleep(0.2)
        'never reached in practice'
      end
    end

    it 'times out' do
      expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id, file_name: file_name,
        class_name: described_class.name.demodulize
      )

      expect(render(file_name, text, context)).to eq("<p>#{text}</p>")
    end

    it 'renders the input as escaped plain text, not as markup' do
      allow(GitHub::Markup).to receive(:render) do
        sleep(0.2)
        'never reached in practice'
      end

      rendered = render(file_name, +'<div class="js-infinite-scrolling-root">x</div>', context)
      doc = Nokogiri::HTML5.fragment(rendered)

      expect(doc.css('div')).to be_empty
      expect(rendered).to include('&lt;div')
    end
  end

  context 'when the markup renderer raises a command error' do
    let(:file_name) { 'unimportant_name.rst' }
    let(:context) { {} }

    before do
      allow(GitHub::Markup).to receive(:render).and_raise(GitHub::Markup::CommandError)
    end

    it 'renders the input as escaped plain text instead of failing' do
      input = <<~RST
        first line
        second line

        new paragraph
      RST

      rendered = render(file_name, input, context)

      expect(rendered).to eq_html("<p>first line\n<br />second line</p>\n\n<p>new paragraph\n</p>")
    end

    it 'does not interpret the input as HTML' do
      input = <<~RST
        ++++
        <div class="project-show-activity">
            <div class="content_list" data-href="/test">
                <div class="js-infinite-scrolling-root"></div>
            </div>
        </div>
      RST

      rendered = render(file_name, input, context)
      doc = Nokogiri::HTML5.fragment(rendered)

      %w[project-show-activity content_list js-infinite-scrolling-root].each do |klass|
        expect(doc.css(".#{klass}")).to be_empty
      end
      expect(doc.css('[data-href]')).to be_empty
      expect(rendered).to include('&lt;div')
    end
  end

  context 'RedCloth markup' do
    let(:file_name) { 'file.textile' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML.fragment(rendered) }

    it 'renders textile correctly' do
      test_text = '"This is *my* text."'
      expected_res = "<p>&#8220;This is <strong>my</strong> text.&#8221;</p>"
      expect(RedCloth.new(test_text).to_html).to eq(expected_res)
    end

    context 'with headings' do
      let(:input) do
        <<~TEXTILE
          h1. Heading 1

          h2. Heading 2

          h3. Heading 3

          h4. Heading 4

          h5. Heading 5

          h6. Heading 6

          h2. Another H2
        TEXTILE
      end

      it 'adds heading IDs and anchor links for table of contents' do
        headings = doc.css('h1, h2, h3, h4, h5, h6')

        expect(headings.size).to eq(7)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h1')['id']).to eq('user-content-heading-1')
        expect(doc.at_css('h1 a.anchor')['href']).to eq('#heading-1')
        expect(doc.at_css('h6')['id']).to eq('user-content-heading-6')
        expect(doc.at_css('h6 a.anchor')['href']).to eq('#heading-6')
      end
    end

    context 'with custom heading ids' do
      let(:input) do
        <<~TEXTILE
          h1(#custom-h1). Heading 1

          h2(#custom-h2). Heading 2
        TEXTILE
      end

      it 'preserves custom heading ids and adds anchor links for table of contents' do
        headings = doc.css('h1, h2')

        expect(headings.size).to eq(2)

        headings.each do |heading|
          expect(heading['id']).to start_with('user-content-')
          expect(heading.at_css('a.anchor')).to be_present
        end

        expect(doc.at_css('h1')['id']).to eq('user-content-custom-h1')
        expect(doc.at_css('h1 a.anchor')['href']).to eq('#custom-h1')
        expect(doc.at_css('h2')['id']).to eq('user-content-custom-h2')
        expect(doc.at_css('h2 a.anchor')['href']).to eq('#custom-h2')
      end
    end

    it 'protects against malicious backtracking',
      quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/5638' do
      test_text = '<A' + ('A' * 54773)

      expect do
        Timeout.timeout(Gitlab::OtherMarkup::RENDER_TIMEOUT.seconds) do
          RedCloth.new(test_text, [:sanitize_html]).to_html
        end
      end.not_to raise_error
    end
  end

  def render(...)
    described_class.render(...)
  end
end
