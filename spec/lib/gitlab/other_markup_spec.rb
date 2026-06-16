# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OtherMarkup, feature_category: :wiki do
  let(:context) { {} }

  context 'when org-mode content' do
    let(:file_name) { 'unimportant_name.org' }
    let(:rendered) { render(file_name, input, context) }
    let(:doc) { Nokogiri::HTML.fragment(rendered) }
    let(:pre) { doc.css('pre').first }

    context 'with auto-linking' do
      let(:input) { 'See https://example.com for details.' }

      it 'auto-links bare URLs', :aggregate_failures do
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

      it 'applies the canonical language attribute' do
        expect(pre['data-canonical-lang']).to eq('mermaid')
      end

      it 'adds the JS hook for client-side rendering' do
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

      it 'applies the canonical language attribute' do
        expect(pre['data-canonical-lang']).to eq('math')
      end

      it 'preserves the math style attribute' do
        expect(pre['data-math-style']).to eq('display')
      end

      it 'adds the JS hook for math rendering' do
        expect(pre[:class]).to include('js-render-math')
      end
    end
  end

  context 'when restructured text' do
    it 'renders' do
      input = <<~RST
        Header
        ======

        *emphasis*; **strong emphasis**; `interpreted text`
      RST

      output = <<~HTML
        <h1>Header</h1>
        <p><em>emphasis</em>; <strong>strong emphasis</strong>; <cite>interpreted text</cite></p>
      HTML

      expect(render('unimportant_name.rst', input, context)).to include(output.strip)
    end

    context 'when PlantUML is enabled' do
      it 'generates the diagram' do
        Gitlab::CurrentSettings.current_application_settings.update!(plantuml_enabled: true, plantuml_url: 'https://plantuml.com/plantuml')

        input = <<~RST
          .. plantuml::
                 :caption: Caption with **bold** and *italic*

                 Bob -> Alice: hello
                 Alice -> Bob: hi
        RST

        output = <<~HTML
          <img class="plantuml" src="https://plantuml.com/plantuml/png/U9npoazIqBLJSCp9J4wrKiX8pSd9vm9pGA9E-Kb0iKm0o4SAt000" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IEFsaWNlOiBoZWxsbwpBbGljZSAtPiBCb2I6IGhp">
          <p>Caption with <strong>bold</strong> and <em>italic</em></p>
        HTML

        expect(render('unimportant_name.rst', input, context)).to include(output.strip)
      end
    end

    it 'renders mermaid diagrams' do
      input = <<~RST
        .. code:: mermaid

           graph TD;
               A-->B;
               A-->C;
               B-->D;
               C-->D;
      RST

      result = render('unimportant_name.rst', input, context)
      doc = Nokogiri::HTML.fragment(result)
      pre = doc.css('pre').first
      expect(pre['data-canonical-lang']).to eq('mermaid')
      expect(pre.at_css('code')[:class]).to include('js-render-mermaid')
    end

    it 'renders math source blocks' do
      input = <<~RST
        .. code:: math

           \\sqrt{2}
      RST

      result = render('unimportant_name.rst', input, context)
      doc = Nokogiri::HTML.fragment(result)
      pre = doc.css('pre').first
      expect(pre['data-canonical-lang']).to eq('math')
      expect(pre['data-math-style']).to eq('display')
      expect(pre[:class]).to include('js-render-math')
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
    links = {
      'p' => {
        file: 'file.mediawiki',
        input: 'Red Bridge (JRuby Embed)',
        output: "\n<p>Red Bridge (JRuby Embed)</p>"
      },
      'h1' => {
        file: 'file.mediawiki',
        input: '= Red Bridge (JRuby Embed) =',
        output: "\n\n<h1>\n<a name=\"Red_Bridge_JRuby_Embed\"></a><span>Red Bridge (JRuby Embed)</span>\n</h1>\n"
      },
      'h2' => {
        file: 'file.mediawiki',
        input: '== Red Bridge (JRuby Embed) ==',
        output: "\n\n<h2>\n<a name=\"Red_Bridge_JRuby_Embed\"></a><span>Red Bridge (JRuby Embed)</span>\n</h2>\n"
      }
    }
    links.each do |name, data|
      it "does render into #{name} element" do
        expect(render(data[:file], data[:input], context)).to eq_html(data[:output], trim_text_nodes: true)
      end
    end
  end

  context 'when rendering takes too long' do
    let_it_be(:file_name, freeze: false) { 'foo.bar' }
    let_it_be(:project, freeze: false) { create(:project, :repository) }
    let_it_be(:context, freeze: false) { { project: project } }
    let_it_be(:text, freeze: false) { +'Noël' }

    before do
      stub_const('Gitlab::OtherMarkup::RENDER_TIMEOUT', 0.1)
      allow(GitHub::Markup).to receive(:render) do
        sleep(0.2)
        text
      end
    end

    it 'times out' do
      # expect at least 2 times because of timeout in SyntaxHighlightFilter
      expect(Gitlab::RenderTimeout).to receive(:timeout).at_least(:twice).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id, file_name: file_name,
        class_name: described_class.name.demodulize
      )

      expect(render(file_name, text, context)).to eq("<p>#{text}</p>")
    end
  end

  context 'RedCloth markup' do
    it 'renders textile correctly' do
      test_text = '"This is *my* text."'
      expected_res = "<p>&#8220;This is <strong>my</strong> text.&#8221;</p>"
      expect(RedCloth.new(test_text).to_html).to eq(expected_res)
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
