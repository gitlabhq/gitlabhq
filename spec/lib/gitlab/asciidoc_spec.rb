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

        expect(render(input, context)).to eq(html)
      end

      context "XSS" do
        links = {
          'links' => {
            input: 'link:mylink"onmouseover="alert(1)[Click Here]',
            output: "<div>\n<p><a href=\"mylink\">Click Here</a></p>\n</div>"
          },
          'images' => {
            input: 'image:https://localhost.com/image.png[Alt text" onerror="alert(7)]',
            output: "<img src=\"https://localhost.com/image.png\" alt=\"Alt text\">"
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

          expect(output).to include('rel="nofollow noreferrer"')
        end
      end
    end

    def render(*args)
      described_class.render(*args)
    end
  end
end
