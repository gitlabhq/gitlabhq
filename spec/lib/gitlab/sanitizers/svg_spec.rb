# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sanitizers::SVG do
  let(:scrubber) { Gitlab::Sanitizers::SVG::Scrubber.new }
  let(:namespace) { double(Nokogiri::XML::Namespace, prefix: 'xlink', href: 'http://www.w3.org/1999/xlink') }
  let(:namespaced_attr) { double(Nokogiri::XML::Attr, name: 'href', namespace: namespace, value: '#awesome_id') }

  describe '.clean' do
    let(:input_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'unsanitized.svg') }
    let(:data) { File.read(input_svg_path) }
    let(:sanitized_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'sanitized.svg') }
    let(:sanitized) { File.read(sanitized_svg_path) }

    it 'delegates sanitization to scrubber' do
      expect_next_instance_of(Gitlab::Sanitizers::SVG::Scrubber) do |instance|
        expect(instance).to receive(:scrub).at_least(:once)
      end
      described_class.clean(data)
    end

    it 'returns sanitized data' do
      expect(described_class.clean(data)).to eq(sanitized)
    end
  end

  context 'scrubber' do
    describe '#scrub' do
      let(:invalid_element) { double(Nokogiri::XML::Node, name: 'invalid', value: 'invalid') }
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

    describe '#unsafe_href?' do
      let(:unsafe_attr) { double(Nokogiri::XML::Attr, name: 'href', namespace: namespace, value: 'http://evilsite.example.com/random.svg') }

      it 'returns true if href attribute is an external url' do
        expect(scrubber.unsafe_href?(unsafe_attr)).to be_truthy
      end

      it 'returns false if href atttribute is an internal reference' do
        expect(scrubber.unsafe_href?(namespaced_attr)).to be_falsey
      end
    end

    describe '#data_attribute?' do
      let(:data_attr) { double(Nokogiri::XML::Attr, name: 'data-gitlab', namespace: nil, value: 'gitlab is awesome') }
      let(:namespaced_attr) { double(Nokogiri::XML::Attr, name: 'data-gitlab', namespace: namespace, value: 'gitlab is awesome') }
      let(:other_attr) { double(Nokogiri::XML::Attr, name: 'something', namespace: nil, value: 'content') }

      it 'returns true if is a valid data attribute' do
        expect(scrubber.data_attribute?(data_attr)).to be_truthy
      end

      it 'returns false if attribute is namespaced' do
        expect(scrubber.data_attribute?(namespaced_attr)).to be_falsey
      end

      it 'returns false if not a data attribute' do
        expect(scrubber.data_attribute?(other_attr)).to be_falsey
      end
    end
  end
end
