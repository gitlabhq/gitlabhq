require 'spec_helper'

describe Gitlab::Sanitizers::SVG do
  let(:scrubber) { Gitlab::Sanitizers::SVG::Scrubber.new }
  let(:namespace) { double(Nokogiri::XML::Namespace, prefix: 'xlink') }
  let(:namespaced_attr) { double(Nokogiri::XML::Attr, name: 'href', namespace: namespace) }

  context 'scrubber' do
    describe '#scrub' do
      let(:invalid_element) { double(Nokogiri::XML::Node, name: 'invalid') }
      let(:invalid_attribute) { double(Nokogiri::XML::Attr, name: 'invalid', namespace: nil) }
      let(:valid_element) { double(Nokogiri::XML::Node, name: 'use') }

      it 'removes an invalid element' do
        expect(invalid_element).to receive(:unlink)

        scrubber.scrub(invalid_element)
      end

      it 'removes an invalid attribute' do
        allow(valid_element).to receive(:attribute_nodes) { [invalid_attribute] }
        expect(invalid_attribute).to receive(:unlink)

        scrubber.scrub(valid_element)
      end

      it 'accepts valid element' do
        allow(valid_element).to receive(:attribute_nodes) { [namespaced_attr] }
        expect(valid_element).not_to receive(:unlink)

        scrubber.scrub(valid_element)
      end

      it 'accepts valid namespaced attributes' do
        allow(valid_element).to receive(:attribute_nodes) { [namespaced_attr] }
        expect(namespaced_attr).not_to receive(:unlink)

        scrubber.scrub(valid_element)
      end
    end

    describe '#attribute_name_with_namespace' do
      it 'returns name with prefix when attribute is namespaced' do
        expect(scrubber.attribute_name_with_namespace(namespaced_attr)).to eq('xlink:href')
      end
    end
  end
end
