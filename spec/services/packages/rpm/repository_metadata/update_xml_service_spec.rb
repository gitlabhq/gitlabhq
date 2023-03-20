# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::UpdateXmlService, feature_category: :package_registry do
  describe '#execute' do
    subject { described_class.new(filename: filename, xml: xml, data: data).execute }

    let(:xml) { nil }
    let(:data) { nil }

    shared_examples 'handling not implemented xml filename' do
      let(:filename) { :not_implemented_yet }
      let(:empty_xml) { '' }

      it 'raise error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    shared_context 'with primary xml file data' do
      let(:filename) { :primary }
      let(:empty_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" packages="0"/>
        XML
      end
    end

    shared_context 'with other xml file data' do
      let(:filename) { :other }
      let(:empty_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <otherdata xmlns="http://linux.duke.edu/metadata/other" packages="0"/>
        XML
      end
    end

    shared_context 'with filelist xml file data' do
      let(:filename) { :filelist }
      let(:empty_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <filelists xmlns="http://linux.duke.edu/metadata/filelists" packages="0"/>
        XML
      end
    end

    context 'when building empty xml' do
      shared_examples 'generating empty xml' do
        it 'generate expected xml' do
          expect(subject).to eq(empty_xml)
        end
      end

      it_behaves_like 'handling not implemented xml filename'

      context "for 'primary' xml file" do
        include_context 'with primary xml file data'

        it_behaves_like 'generating empty xml'
      end

      context "for 'other' xml file" do
        include_context 'with other xml file data'

        it_behaves_like 'generating empty xml'
      end

      context "for 'filelist' xml file" do
        include_context 'with filelist xml file data'

        it_behaves_like 'generating empty xml'
      end
    end

    context 'when updating xml file' do
      include_context 'with rpm package data'

      let(:xml) { empty_xml }
      let(:data) { xml_update_params }
      let(:builder_class) { described_class::BUILDERS[filename] }

      shared_examples 'updating rpm xml file' do
        context 'when updating existing xml' do
          shared_examples 'changing root tag attribute' do
            it "increment previous 'packages' value by 1" do
              previous_value = Nokogiri::XML(xml).at(builder_class::ROOT_TAG).attributes["packages"].value.to_i
              new_value = Nokogiri::XML(subject).at(builder_class::ROOT_TAG).attributes["packages"].value.to_i

              expect(previous_value + 1).to eq(new_value)
            end
          end

          it 'generate valid xml add expected xml node to existing xml' do
            # Have one root attribute
            result = Nokogiri::XML::Document.parse(subject).remove_namespaces!
            expect(result.children.count).to eq(1)

            # Root node has 1 child with generated node
            expect(result.xpath("//#{builder_class::ROOT_TAG}/package").count).to eq(1)
          end

          context 'when empty xml' do
            it_behaves_like 'changing root tag attribute'
          end

          context 'when xml has children' do
            context "when node with given 'pkgid' does not exist yet" do
              let(:uniq_node_data) do
                xml_update_params.tap do |data|
                  data[:pkgid] = SecureRandom.uuid
                end
              end

              let(:xml) { build_xml_from(uniq_node_data) }

              it 'has children nodes' do
                existing_xml = Nokogiri::XML::Document.parse(xml).remove_namespaces!
                expect(existing_xml.xpath('//package').count).to eq(1)
              end

              it_behaves_like 'changing root tag attribute'
            end

            context "when node with given 'pkgid' already exist" do
              let(:existing_node_data) do
                existing_data = data.dup
                existing_data[:name] = FFaker::Lorem.word
                existing_data
              end

              let(:xml) { build_xml_from(existing_node_data) }

              it 'has children nodes' do
                existing_xml = Nokogiri::XML::Document.parse(xml).remove_namespaces!
                expect(existing_xml.xpath('//package').count).to eq(1)
              end

              it 'replace existing node with new data' do
                existing_xml = Nokogiri::XML::Document.parse(xml).remove_namespaces!
                result = Nokogiri::XML::Document.parse(subject).remove_namespaces!
                expect(result.xpath('//package').count).to eq(1)
                expect(result.xpath('//package').first.to_xml).not_to eq(existing_xml.xpath('//package').first.to_xml)
              end
            end

            def build_xml_from(data)
              described_class.new(filename: filename, xml: empty_xml, data: data).execute
            end
          end
        end
      end

      it_behaves_like 'handling not implemented xml filename'

      context "for 'primary' xml file" do
        include_context 'with primary xml file data'

        it_behaves_like 'updating rpm xml file'
      end

      context "for 'other' xml file" do
        include_context 'with other xml file data'

        it_behaves_like 'updating rpm xml file'
      end

      context "for 'filelist' xml file" do
        include_context 'with filelist xml file data'

        it_behaves_like 'updating rpm xml file'
      end
    end
  end
end
