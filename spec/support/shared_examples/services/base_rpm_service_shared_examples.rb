# frozen_string_literal: true

RSpec.shared_examples 'handling rpm xml file' do
  include_context 'with rpm package data'

  let(:xml) { nil }
  let(:data) { {} }

  context 'when generate empty xml' do
    it 'generate expected xml' do
      expect(subject).to eq(empty_xml)
    end
  end

  context 'when updating existing xml' do
    let(:xml) { empty_xml }
    let(:data) { xml_update_params }

    shared_examples 'changing root tag attribute' do
      it "increment previous 'packages' value by 1" do
        previous_value = Nokogiri::XML(xml).at(described_class::ROOT_TAG).attributes["packages"].value.to_i
        new_value = Nokogiri::XML(subject).at(described_class::ROOT_TAG).attributes["packages"].value.to_i

        expect(previous_value + 1).to eq(new_value)
      end
    end

    it 'generate valid xml add expected xml node to existing xml' do
      # Have one root attribute
      result = Nokogiri::XML::Document.parse(subject).remove_namespaces!
      expect(result.children.count).to eq(1)

      # Root node has 1 child with generated node
      expect(result.xpath("//#{described_class::ROOT_TAG}/package").count).to eq(1)
    end

    context 'when empty xml' do
      it_behaves_like 'changing root tag attribute'
    end

    context 'when xml has children' do
      let(:xml) { described_class.new(xml: empty_xml, data: data).execute }

      it 'has children nodes' do
        result = Nokogiri::XML::Document.parse(xml).remove_namespaces!
        expect(result.children.count).to be > 0
      end

      it_behaves_like 'changing root tag attribute'
    end
  end
end
