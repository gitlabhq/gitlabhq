require 'spec_helper'
require 'nokogiri'

module Gitlab
  describe Asciidoc do

    let(:input) { '<b>ascii</b>' }
    let(:context) { {} }
    let(:html) { 'H<sub>2</sub>O' }

    context "without project" do

      it "should convert the input using Asciidoctor and default options" do
        expected_asciidoc_opts = {
            safe: :secure,
            backend: :html5,
            attributes: described_class::DEFAULT_ADOC_ATTRS
        }

        expect(Asciidoctor).to receive(:convert)
          .with(input, expected_asciidoc_opts).and_return(html)

        expect( render(input, context) ).to eql html
      end

      context "with asciidoc_opts" do

        let(:asciidoc_opts) { { safe: :safe, attributes: ['foo'] } }

        it "should merge the options with default ones" do
          expected_asciidoc_opts = {
              safe: :safe,
              backend: :html5,
              attributes: described_class::DEFAULT_ADOC_ATTRS + ['foo']
          }

          expect(Asciidoctor).to receive(:convert)
            .with(input, expected_asciidoc_opts).and_return(html)

          render(input, context, asciidoc_opts)
        end
      end
    end

    context "with project in context" do

      let(:context) { { project: create(:project) } }

      it "should filter converted input via HTML pipeline and return result" do
        filtered_html = '<b>ASCII</b>'

        allow(Asciidoctor).to receive(:convert).and_return(html)
        expect_any_instance_of(HTML::Pipeline).to receive(:call)
          .with(html, context)
          .and_return(output: Nokogiri::HTML.fragment(filtered_html))

        expect( render('foo', context) ).to eql filtered_html
      end
    end

    def render(*args)
      described_class.render(*args)
    end
  end
end
