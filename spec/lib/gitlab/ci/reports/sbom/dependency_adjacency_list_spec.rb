# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::DependencyAdjacencyList, feature_category: :dependency_management do
  subject(:dependency_list) { described_class.new }

  let(:child) { 'child-ref' }

  describe 'without any data' do
    it 'does not return any ancestor' do
      expect(dependency_list.ancestors_for(child)).to be_empty
    end
  end

  describe 'with only relationship data' do
    let(:parent) { 'parent-ref' }

    before do
      dependency_list.add_edge(parent, child)
    end

    it 'does not return any ancestor' do
      expect(dependency_list.ancestors_for(child)).to be_empty
    end

    context 'with component data' do
      let(:component_data) { { name: 'component_name', version: 'component_version' } }

      before do
        dependency_list.add_component_info(parent, component_data[:name], component_data[:version])
      end

      it 'returns the ancestor' do
        expect(dependency_list.ancestors_for(child)).to eq([component_data])
      end

      context 'with multiple ancestors' do
        let(:component_data_2) { { name: 'component_name_2', version: 'component_version_2' } }
        let(:parent_2) { 'parent_2-ref' }

        before do
          dependency_list.add_component_info(parent_2, component_data_2[:name], component_data_2[:version])
          dependency_list.add_edge(parent_2, child)
        end

        it 'returns the ancestor' do
          expect(dependency_list.ancestors_for(child)).to contain_exactly(component_data, component_data_2)
        end
      end
    end
  end
end
