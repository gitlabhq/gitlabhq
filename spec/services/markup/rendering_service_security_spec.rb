# frozen_string_literal: true

require 'spec_helper'

# This spec suite tests the Markup::RenderingService for potential file
# inclusion vulnerabilities.
#
# Any failure here should be reviewed by AppSec if it indicates the
# inclusion of file contents. A benign change would be minor
# variations in how markup is converted into HTML.
#
# This serves as a defense-in-depth measure to detect if any changes
# introduce arbitrary file read or inclusion vulnerabilities across
# various markup formats.
#
# The suite covers:
# - Multiple markup languages
# - Various file inclusion techniques specific to each markup language
# - Encoding and compression methods that might be used to obfuscate
#   file contents (either by the markup renderer, or an attacker)
RSpec.describe Markup::RenderingService, feature_category: :markdown do
  let_it_be(:project) { build(:project) }
  let(:context) do
    {
      project: project,
      ref: 'main',
      requested_path: file_name
    }
  end

  describe 'file inclusion protections' do
    before do
      allow(Gitlab::CurrentSettings).to receive_messages(
        kroki_enabled: true,
        kroki_formats: %w[blockdiag bpmn bytefield seqdiag actdiag nwdiag dot graphviz mermaid nomnoml plantuml svgbob
          umlet wavedrom excalidraw erd ditaa],
        plantuml_enabled: true,
        asset_proxy_enabled: false
      )
    end

    describe 'AsciiDoc' do
      let(:file_name) { 'test.adoc' }

      it 'does not allow reading arbitrary files via basic include directives' do
        # https://docs.asciidoctor.org/asciidoc/latest/directives/include/
        input = 'include::/etc/hosts[]'
        output = render(input, file_name, context)
        expect(output).to include("[ERROR: include::/etc/hosts[] - unresolved directive]")
      end

      it 'does not allow reading arbitrary files via tagged includes' do
        # https://docs.asciidoctor.org/asciidoc/latest/directives/include-tagged/
        input = 'include::/etc/hosts[tags=section]'
        output = render(input, file_name, context)
        expect(output).to include("[ERROR: include::/etc/hosts[] - unresolved directive]")
      end

      it 'does not allow reading arbitrary files via leveloffset include' do
        # https://docs.asciidoctor.org/asciidoc/latest/directives/include-with-leveloffset/
        input = 'include::/etc/hosts[leveloffset=+1]'
        output = render(input, file_name, context)
        expect(output).to include('[ERROR: include::/etc/hosts[] - unresolved directive]')
      end

      it 'does not allow reading arbitrary files via kroki\'s blockdiag macro' do
        # https://docs.kroki.io/kroki/syntax/blockdiag/
        # https://docs.asciidoctor.org/diagram-extension/latest/#blockdiag
        input = <<~ADOC
          = File Read Test

          blockdiag::/etc/hosts[format=svg]
        ADOC

        output = render(input, file_name, context)
        expect(output).to include('<p>blockdiag::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via plantuml macro' do
        # https://plantuml.com/preprocessing
        # https://docs.asciidoctor.org/diagram-extension/latest/#plantuml
        input = <<~ADOC
          = File Read Test

          plantuml::/etc/hosts[format=svg]
        ADOC

        output = render(input, file_name, context)
        expect(output).to include('<p>plantuml::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via graphviz macro' do
        # https://docs.asciidoctor.org/diagram-extension/latest/#graphviz
        # https://graphviz.org/doc/info/command.html
        input = <<~ADOC
          = File Read Test

          graphviz::/etc/hosts[format=svg]
        ADOC

        output = render(input, file_name, context)
        expect(output).to include('<p>graphviz::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via ditaa macro' do
        # https://docs.asciidoctor.org/diagram-extension/latest/#ditaa
        input = <<~ADOC
          = File Read Test

          ditaa::/etc/hosts[format=png]
        ADOC
        output = render(input, file_name, context)
        expect(output).to include('<p>ditaa::/etc/hosts[format=png]</p>')
      end

      it 'does not allow reading arbitrary files via mermaid macro' do
        # https://mermaid.js.org/syntax/stateDiagram.html
        # Uses different processing path from other diagram types
        input = <<~ADOC
          = File Read Test

          mermaid::/etc/hosts[format=svg]
        ADOC
        output = render(input, file_name, context)
        expect(output).to include('<p>mermaid::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via svgbob macro' do
        # https://github.com/ivanceras/svgbob
        # Direct ASCII-to-SVG converter with its own processing
        input = <<~ADOC
          = File Read Test

          svgbob::/etc/hosts[format=svg]
        ADOC
        output = render(input, file_name, context)
        expect(output).to include('<p>svgbob::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via mathematical macro' do
        # https://docs.asciidoctor.org/mathematical-extension/latest/
        # Uses Mathematical gem which has its own TeX/LaTeX processor
        input = <<~ADOC
          = File Read Test

          math::/etc/hosts[format=svg]
        ADOC
        output = render(input, file_name, context)
        expect(output).to include('<p>math::/etc/hosts[format=svg]</p>')
      end

      it 'does not allow reading arbitrary files via stem blocks' do
        # https://docs.asciidoctor.org/asciidoc/latest/stem/
        # Uses separate STEM processor (MathJax/KaTeX path)
        input = <<~ADOC
          [stem]
          ++++
          \\input{/etc/hosts}
          ++++
        ADOC
        output = render(input, file_name, context)
        expect(output).to include("<div>\n\\$\\input{/etc/hosts}\\$\n</div>")
      end

      it 'does not allow reading arbitrary files via gnuplot blocks' do
        # https://docs.asciidoctor.org/diagram-extension/latest/#gnuplot
        # GnuPlot has its own file loading mechanisms
        input = <<~ADOC
          = File Read Test

          [gnuplot]
          ----
          load '/etc/hosts'
          ----
        ADOC
        output = render(input, file_name, context)
        expect(output).to include("<pre>load '/etc/hosts'</pre>")
      end
    end

    # Note: if running these tests locally, ensure docutils is installed
    # using `pipenv install`.
    # See: doc/development/python_guide/index.md.
    describe 'reStructuredText' do
      let(:file_name) { 'test.rst' }

      it 'does not allow reading arbitrary files via include directive' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#including-an-external-document-fragment
        input = '.. include:: /etc/hosts'
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via csv-table directive' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#csv-table
        input = <<~RST
          .. csv-table::
              :file: /etc/hosts
        RST
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via raw directive' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#raw-data-pass-through
        input = ".. raw:: html\n   :file: /etc/hosts"
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via math directive' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#math
        # Uses separate math rendering pipeline
        input = <<~RST
          .. math::
             :file: /etc/hosts
        RST
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via figure directive' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#figure
        # Image processing path differs from regular includes
        input = <<~RST
          .. figure:: /etc/hosts
             :align: center
        RST
        output = render(input, file_name, context)
        expect(output).to eq("<div>\n<img alt=\"/etc/hosts\" src=\"/etc/hosts\">\n</div>\n\n")
      end

      it 'does not allow reading arbitrary files via code directives' do
        # https://docutils.sourceforge.io/docs/ref/rst/directives.html#code
        # Code highlighting path
        input = <<~RST
          .. code:: ruby
             :file: /etc/hosts
        RST
        output = render(input, file_name, context)
        expect(output).to eq('')
      end
    end

    describe 'MediaWiki' do
      let(:file_name) { 'test.wiki' }

      it 'does not allow reading arbitrary files via transclusion' do
        # https://www.mediawiki.org/wiki/Help:Templates#Including_one_page_in_another
        input = '{{:/etc/hosts}}'
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via preprocessor directives' do
        # https://www.mediawiki.org/wiki/Manual:Preprocessor
        # Uses separate preprocessing pipeline
        input = '{{{file:/etc/hosts}}}'
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via file inclusion' do
        # https://www.mediawiki.org/wiki/Help:Images#Syntax
        input = '[[File:/etc/hosts]]'
        output = render(input, file_name, context)
        expect(output).to eq("\n<p><img src=\"/etc/hosts\" alt=\"File:/etc/hosts\" title=\"File:/etc/hosts\"></p>")
      end

      it 'does not allow reading arbitrary files via template inclusions with variables' do
        # https://www.mediawiki.org/wiki/Help:Templates#Parameter_handling
        # Template processor has separate expansion path
        input = '{{:/etc/hosts|path={{{1}}}}}'
        output = render(input, file_name, context)
        expect(output).to eq('')
      end
    end

    describe 'Org mode' do
      let(:file_name) { 'test.org' }

      it 'does not allow reading arbitrary files via include directive' do
        # https://orgmode.org/manual/Include-Files.html
        input = '#+INCLUDE: "/etc/hosts"'
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via babel source blocks' do
        # https://orgmode.org/worg/org-contrib/babel/intro.html#source-code-blocks
        input = '#+BEGIN_SRC ruby :var data=/etc/hosts'
        output = render(input, file_name, context)
        expect(output).to eq("<pre lang=\"ruby\">\n</pre>\n")
      end

      it 'does not allow reading arbitrary files via ditaa blocks' do
        # http://ditaa.sourceforge.net/
        # Direct ASCII-to-PNG converter with its own file handling
        input = <<~ORG
          #+BEGIN_DITAA /etc/hosts
          +---------+
          | Box     |
          +---------+
        ORG
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via latex export blocks' do
        # https://orgmode.org/manual/LaTeX-Export.html
        # Uses separate LaTeX processing path
        input = <<~ORG
          #+LATEX_HEADER: \\input{/etc/hosts}
          #+BEGIN_EXPORT latex
          \\include{/etc/hosts}
          #+END_EXPORT
        ORG
        output = render(input, file_name, context)
        expect(output).to eq('')
      end
    end

    describe 'Markdown' do
      let(:file_name) { 'test.md' }

      it 'does not allow reading arbitrary files via HTML include tags' do
        # While not standard Markdown, this is a common extension
        # https://github.com/webcomponents/html-imports
        input = "<include src='/etc/hosts' />"
        output = render(input, file_name, context)
        expect(output).to eq('')
      end

      it 'does not allow reading arbitrary files via iframe tags' do
        # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe
        input = "<iframe src='/etc/hosts'></iframe>"
        output = render(input, file_name, context)
        expect(output).to eq('')
      end
    end
  end

  describe 'Textile' do
    let(:file_name) { 'test.textile' }

    it 'does not allow reading arbitrary files via HTML include tags' do
      # https://textile-lang.com/doc/html-integration
      input = "<include src='/etc/hosts' />"
      output = render(input, file_name, context)
      expect(output).to eq('')
    end

    it 'does not allow reading arbitrary files via SSI directives' do
      # Server-side includes sometimes processed by textile renderers
      # https://httpd.apache.org/docs/current/howto/ssi.html
      input = "<!--#include virtual='/etc/hosts' -->"
      output = render(input, file_name, context)
      expect(output).to eq('<p></p>')
    end
  end

  describe 'Creole' do
    let(:file_name) { 'test.creole' }

    it 'does not allow reading arbitrary files via include macro' do
      # http://www.wikicreole.org/wiki/Macros
      input = "<<include /etc/hosts>>"
      output = render(input, file_name, context)
      expect(output).to eq('<p>&lt;&lt;include /etc/hosts&gt;&gt;</p>')
    end

    it 'does not allow reading arbitrary files via image syntax' do
      # http://www.wikicreole.org/wiki/CheatSheet
      input = "{{/etc/hosts}}"
      output = render(input, file_name, context)
      # In this case, the browser _might_ attempt to read the attacker's
      # etc/hosts, but it's not the server's /etc/hosts
      expect(output).to eq("<p><img src=\"/etc/hosts\"></p>")
    end
  end

  private

  def render(content, file_name, context)
    described_class.new(
      content,
      file_name: file_name,
      context: context
    ).execute
  end
end
