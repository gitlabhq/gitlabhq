require 'spec_helper'
require 'nokogiri'

module Gitlab
  describe Asciidoc, lib: true do
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

        expect( render(input, context) ).to eql html
      end

      context "with asciidoc_opts" do
        let(:asciidoc_opts) { { safe: :safe, attributes: ['foo'] } }

        it "merges the options with default ones" do
          expected_asciidoc_opts = {
              safe: :safe,
              backend: :gitlab_html5,
              attributes: described_class::DEFAULT_ADOC_ATTRS + ['foo']
          }

          expect(Asciidoctor).to receive(:convert)
            .with(input, expected_asciidoc_opts).and_return(html)

          render(input, context, asciidoc_opts)
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
            output: "<div>\n<p><span><img src=\"https://localhost.com/image.png\" alt=\"Alt text\"></span></p>\n</div>"
          },
          'pre' => {
            input: '```mypre"><script>alert(3)</script>',
            output: "<div>\n<div>\n<pre lang=\"mypre\">\"&gt;<code></code></pre>\n</div>\n</div>"
          }
        }

        links.each do |name, data|
          it "does not convert dangerous #{name} into HTML" do
            expect(render(data[:input], context)).to eql data[:output]
          end
        end
      end
    end

    def render(*args)
      described_class.render(*args)
    end
  end
end
