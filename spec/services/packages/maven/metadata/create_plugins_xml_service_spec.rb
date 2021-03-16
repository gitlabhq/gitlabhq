# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::Metadata::CreatePluginsXmlService do
  let_it_be(:group_id) { 'my/test' }
  let_it_be(:package) { create(:maven_package, name: group_id, version: nil) }

  let(:plugins_in_database) { %w[one-maven-plugin two three-maven-plugin] }
  let(:plugins_in_xml) { %w[one-maven-plugin two three-maven-plugin] }
  let(:service) { described_class.new(metadata_content: metadata_xml, package: package) }

  describe '#execute' do
    subject { service.execute }

    before do
      next unless package

      plugins_in_database.each do |plugin|
        create(
          :maven_package,
          name: "#{group_id}/#{plugin}",
          version: '1.0.0',
          project: package.project,
          maven_metadatum_attributes: {
            app_group: group_id.tr('/', '.'),
            app_name: plugin,
            app_version: '1.0.0'
          }
        )
      end
    end

    shared_examples 'returning an xml with plugins from the database' do
      it 'returns an metadata versions xml with versions in the database', :aggregate_failures do
        expect(subject).to be_success
        expect(subject.payload[:changes_exist]).to eq(true)
        expect(subject.payload[:empty_versions]).to eq(false)
        expect(plugins_from(subject.payload[:metadata_content])).to match_array(plugins_in_database)
      end
    end

    shared_examples 'returning no changes' do
      it 'returns no changes', :aggregate_failures do
        expect(subject).to be_success
        expect(subject.payload).to eq(changes_exist: false, empty_versions: false)
      end
    end

    context 'with same plugins on both sides' do
      it_behaves_like 'returning no changes'
    end

    context 'with more plugins' do
      let(:additional_plugins) { %w[four-maven-plugin five] }

      context 'in database' do
        let(:plugins_in_database) { plugins_in_xml + additional_plugins }

        # we can't distinguish that the additional plugin are actually maven plugins
        it_behaves_like 'returning no changes'
      end

      context 'in xml' do
        let(:plugins_in_xml) { plugins_in_database + additional_plugins }

        it_behaves_like 'returning an xml with plugins from the database'
      end
    end

    context 'with no versions in the database' do
      let(:plugins_in_database) { [] }

      it 'returns a success', :aggregate_failures do
        result = subject

        expect(result).to be_success
        expect(result.payload).to eq(changes_exist: true, empty_plugins: true)
      end
    end

    context 'with an incomplete metadata content' do
      let(:metadata_xml) { '<metadata></metadata>' }

      it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
    end

    context 'with an invalid metadata content' do
      let(:metadata_xml) { '<meta></metadata>' }

      it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
    end

    it_behaves_like 'handling metadata content pointing to a file for the create xml service'

    it_behaves_like 'handling invalid parameters for create xml service'
  end

  def metadata_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.metadata do
        xml.plugins do
          plugins_in_xml.each do |plugin|
            xml.plugin do
              xml.name(plugin)
              xml.prefix(prefix_from(plugin))
              xml.artifactId(plugin)
            end
          end
        end
      end
    end.to_xml
  end

  def prefix_from(artifact_id)
    artifact_id.gsub(/-?maven-?/, '')
               .gsub(/-?plugin-?/, '')
  end

  def plugins_from(xml_content)
    doc = Nokogiri::XML(xml_content)
    doc.xpath('//metadata/plugins/plugin/artifactId').map(&:content)
  end
end
