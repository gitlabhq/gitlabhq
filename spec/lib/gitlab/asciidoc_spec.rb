require 'spec_helper'
require 'nokogiri'

module Gitlab
  describe Asciidoc do
    let(:input) { '<b>ascii</b>' }
    let(:context) { {} }
    let(:html) { 'H<sub>2</sub>O' }

    context "without project" do
      before do
        allow_any_instance_of(ApplicationSetting).to receive(:current).and_return(::ApplicationSetting.create_from_defaults)
      end

      it "converts the input using Asciidoctor and default options" do
        expected_asciidoc_opts = {
            safe: :secure,
            backend: :gitlab_html5,
            attributes: described_class::DEFAULT_ADOC_ATTRS
        }

        expect(Asciidoctor).to receive(:convert)
          .with(input, expected_asciidoc_opts).and_return(html)

        expect(render(input, context)).to eq(html)
      end

      context "with asciidoc_opts" do
        it "merges the options with default ones" do
          expected_asciidoc_opts = {
              safe: :secure,
              backend: :gitlab_html5,
              attributes: described_class::DEFAULT_ADOC_ATTRS
          }

          expect(Asciidoctor).to receive(:convert)
            .with(input, expected_asciidoc_opts).and_return(html)

          render(input, context)
        end
      end

      context "XSS" do
        links = {
          'links' => {
            input: 'link:mylink"onmouseover="alert(1)[Click Here]',
            output: "<div>\n<p><a href=\"mylink\">Click Here</a></p>\n</div>"
          },
          'images' => {
            input: 'image:https://localhost.com/image.png[Alt text" onerror="alert(7)]',
            output: "<div>\n<p><span><img src=\"https://localhost.com/image.png\" alt='Alt text\" onerror=\"alert(7)'></span></p>\n</div>"
          },
          'pre' => {
            input: '```mypre"><script>alert(3)</script>',
            output: "<div>\n<div>\n<pre lang=\"mypre\">\"&gt;<code></code></pre>\n</div>\n</div>"
          }
        }

        links.each do |name, data|
          it "does not convert dangerous #{name} into HTML" do
            expect(render(data[:input], context)).to include(data[:output])
          end
        end
      end

      context 'external links' do
        it 'adds the `rel` attribute to the link' do
          output = render('link:https://google.com[Google]', context)

          expect(output).to include('rel="nofollow noreferrer noopener"')
        end
      end

      context 'LaTex code' do
        it 'adds class js-render-math to the output' do
          input = <<~MD
            :stem: latexmath

            [stem]
            ++++
            \sqrt{4} = 2
            ++++

            another part

            [latexmath]
            ++++
            \beta_x \gamma
            ++++

            stem:[2+2] is 4
            MD

          expect(render(input, context)).to include('<pre data-math-style="display" class="code math js-render-math"><code>eta_x gamma</code></pre>')
          expect(render(input, context)).to include('<p><code data-math-style="inline" class="code math js-render-math">2+2</code> is 4</p>')
        end
      end

      context 'outfilesuffix' do
        it 'defaults to adoc' do
          output = render("Inter-document reference <<README.adoc#>>", context)

          expect(output).to include("a href=\"README.adoc\"")
        end
      end
    end

    def render(*args)
      described_class.render(*args)
    end
  end
end
