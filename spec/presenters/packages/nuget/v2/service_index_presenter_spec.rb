# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::V2::ServiceIndexPresenter, feature_category: :package_registry do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:group) { build_stubbed(:group) }

  describe '#xml' do
    let(:project_or_group) { project }
    let(:presenter) { described_class.new(project_or_group) }
    let(:xml_doc) { Nokogiri::XML::Document.parse(presenter.xml.to_xml) }
    let(:service_node) { xml_doc.at_xpath('//xmlns:service') }

    it { expect(xml_doc.root.name).to eq('service') }

    it 'includes the workspace and collection nodes' do
      workspace = xml_doc.at_xpath('//xmlns:service/xmlns:workspace')
      collection = xml_doc.at_xpath('//xmlns:service/xmlns:workspace/xmlns:collection')

      expect(workspace).to be_present
      expect(workspace.children).to include(collection)
      expect(collection).to be_present
    end

    it 'sets the appropriate XML namespaces on the root node' do
      expect(service_node.namespaces['xmlns']).to eq('http://www.w3.org/2007/app')
      expect(service_node.namespaces['xmlns:atom']).to eq('http://www.w3.org/2005/Atom')
    end

    context 'when the presenter is initialized with a project' do
      it 'sets the XML base path correctly for a project scope' do
        expect(service_node['xml:base']).to include(expected_xml_base(project))
      end
    end

    context 'when the presenter is initialized with a group' do
      let(:project_or_group) { group }

      it 'sets the XML base path correctly for a group scope' do
        expect(service_node['xml:base']).to include(expected_xml_base(group))
      end
    end
  end

  def expected_xml_base(project_or_group)
    case project_or_group
    when Project
      api_v4_projects_packages_nuget_v2_path(id: project_or_group.id)
    when Group
      api_v4_groups___packages_nuget_v2_path(id: project_or_group.id)
    end
  end
end
