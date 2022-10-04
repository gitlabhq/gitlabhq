# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::BuildPrimaryXml do
  describe '#execute' do
    subject { described_class.new(xml: xml, data: data).execute }

    let(:empty_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" packages="0"/>
      XML
    end

    it_behaves_like 'handling rpm xml file'

    context 'when updating existing xml' do
      include_context 'with rpm package data'

      let(:xml) { empty_xml }
      let(:data) { xml_update_params }
      let(:required_text_only_attributes) { %i[description summary arch name] }

      it 'adds node with required_text_only_attributes' do
        result = Nokogiri::XML::Document.parse(subject).remove_namespaces!

        required_text_only_attributes.each do |attribute|
          expect(
            result.at("//#{described_class::ROOT_TAG}/package/#{attribute}").text
          ).to eq(data[attribute])
        end
      end
    end
  end
end
