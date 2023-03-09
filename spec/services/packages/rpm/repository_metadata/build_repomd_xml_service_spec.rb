# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::BuildRepomdXmlService, feature_category: :package_registry do
  describe '#execute' do
    subject { described_class.new(data).execute }

    let(:data) do
      {
        filelists: {
          checksum: { type: "sha256", value: "123" },
          'open-checksum': { type: "sha256", value: "123" },
          location: { href: "repodata/123-filelists.xml.gz" },
          timestamp: { value: 1644602784 },
          size: { value: 11111 },
          'open-size': { value: 11111 }
        },
        primary: {
          checksum: { type: "sha256", value: "234" },
          'open-checksum': { type: "sha256", value: "234" },
          location: { href: "repodata/234-primary.xml.gz" },
          timestamp: { value: 1644602784 },
          size: { value: 22222 },
          'open-size': { value: 22222 }
        },
        other: {
          checksum: { type: "sha256", value: "345" },
          'open-checksum': { type: "sha256", value: "345" },
          location: { href: "repodata/345-other.xml.gz" },
          timestamp: { value: 1644602784 },
          size: { value: 33333 },
          'open-size': { value: 33333 }
        }
      }
    end

    let(:creation_timestamp) { 111111 }

    before do
      allow(Time).to receive(:now).and_return(creation_timestamp)
    end

    it 'generate valid xml' do
      # Have one root attribute
      result = Nokogiri::XML::Document.parse(subject)
      expect(result.children.count).to eq(1)

      # Root attribute name is 'repomd'
      root = result.children.first
      expect(root.name).to eq('repomd')

      # Have the same count of 'data' tags as count of keys in 'data'
      expect(result.css('data').count).to eq(data.count)
    end

    it 'has all data info' do
      result = Nokogiri::XML::Document.parse(subject).remove_namespaces!

      data.each do |tag_name, tag_attributes|
        tag_attributes.each_key do |key|
          expect(result.at("//repomd/data[@type=\"#{tag_name}\"]/#{key}")).not_to be_nil
        end
      end
    end

    context 'when data values has unexpected keys' do
      let(:data) do
        {
          filelists: described_class::ALLOWED_DATA_VALUE_KEYS.each_with_object({}) do |key, result|
            result[:"#{key}-wrong"] = { value: 'value' }
          end
        }
      end

      it 'ignores wrong keys' do
        result = Nokogiri::XML::Document.parse(subject).remove_namespaces!

        data.each do |tag_name, tag_attributes|
          tag_attributes.each_key do |key|
            expect(result.at("//repomd/data[@type=\"#{tag_name}\"]/#{key}")).to be_nil
          end
        end
      end
    end
  end
end
