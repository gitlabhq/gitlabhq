# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::XmlConverter, feature_category: :pipeline_composition do
  describe '#to_h' do
    let(:xml_data) { '<root><key>value</key></root>' }

    subject(:to_h) { described_class.new(xml_data).to_h }

    context "when the xml is valid" do
      let(:xml_data) { '<root><key>value</key></root>' }

      it "parses the xml with huge option" do
        expect(Nokogiri).to receive(:XML).and_wrap_original do |original_method, *args, &block|
          expect(block).to be(Proc.new(&:huge))
          original_method.call(*args, &block)
        end

        expect(to_h).to eq('root' => { 'key' => 'value' })
      end
    end

    context "when the xml is invalid" do
      let(:xml_data) { '<root><key>value</key>' }

      it "raises an error" do
        expect { to_h }.to raise_error(Nokogiri::XML::SyntaxError)
      end
    end

    context "when the xml is too large" do
      let(:xml_data) { instance_double(String, size: Gitlab::MAX_XML_SIZE + 1) }

      it "raises an error" do
        expect { to_h }.to raise_error(ArgumentError, "The XML file must be less than 30 MB.")
      end
    end

    context "when the xml is empty" do
      let(:xml_data) { '' }

      it "returns nil" do
        expect(to_h).to eq(nil)
      end
    end
  end
end
