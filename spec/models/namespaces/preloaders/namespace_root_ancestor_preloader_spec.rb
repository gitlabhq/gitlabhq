# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Preloaders::NamespaceRootAncestorPreloader, feature_category: :groups_and_projects do
  let_it_be(:parent_public_group) { create(:group) }
  let_it_be(:parent_private_group) { create(:group, :private) }
  let_it_be(:project_namespace) { create(:project_namespace, parent: parent_public_group) }
  let_it_be(:public_group) { create(:group, :private, parent: parent_public_group) }
  let_it_be(:private_group) { create(:group, :private, project_creation_level: nil) }

  let(:root_query_regex) { /\ASELECT.+ FROM find_namespaces_by_id\(\d+\)/ }
  let(:additional_preloads) { [] }
  let(:namespaces) { [project_namespace, public_group, private_group] }
  let(:pristine_namespaces) { Namespace.where(id: namespaces) }

  shared_examples 'executes N matching DB queries' do |expected_query_count, query_method = nil|
    it 'executes the specified root_ancestor queries' do
      expect do
        pristine_namespaces.each do |namespace|
          root_ancestor = namespace.root_ancestor

          root_ancestor.public_send(query_method) if query_method.present?
        end
      end.to make_queries_matching(root_query_regex, expected_query_count)
    end

    it 'strong_memoizes the correct root_ancestor' do
      pristine_namespaces.each do |namespace|
        expected_parent_id = namespace.root_ancestor.id == namespace.id ? nil : namespace.root_ancestor.id

        expect(namespace.parent_id).to eq(expected_parent_id)
      end
    end
  end

  context 'when the preloader is used' do
    before do
      preload_ancestors
    end

    context 'when no additional preloads are provided' do
      it_behaves_like 'executes N matching DB queries', 0
    end

    context 'when additional preloads are provided' do
      let(:additional_preloads) { [:route] }
      let(:root_query_regex) { /\ASELECT.+FROM "routes" WHERE "routes"."source_id" = \d+/ }

      it_behaves_like 'executes N matching DB queries', 0, :full_path
    end
  end

  context 'when the preloader is not used' do
    it_behaves_like 'executes N matching DB queries', 2
  end

  def preload_ancestors
    described_class.new(pristine_namespaces, additional_preloads).execute
  end
end
