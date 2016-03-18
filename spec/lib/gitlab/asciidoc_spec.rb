require 'spec_helper'
require 'nokogiri'

module Gitlab
  describe Asciidoc, lib: true do

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

    def render(*args)
      described_class.render(*args)
    end
  end
end
