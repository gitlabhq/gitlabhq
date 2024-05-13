# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::GroupRootAncestorPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_parent1) { create(:group, :private, name: 'root-1', path: 'root-1') }
  let_it_be(:root_parent2) { create(:group, :private, name: 'root-2', path: 'root-2') }
  let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
  let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer', parent: root_parent1) }
  let_it_be(:private_developer_group) { create(:group, :private, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer') }
  let_it_be(:public_maintainer_group) { create(:group, :private, name: 'a public maintainer', path: 'a-public-maintainer', parent: root_parent2) }

  let(:root_query_regex) do
    if Feature.enabled?(:use_sql_functions_for_primary_key_lookups, Feature.current_request)
      /\ASELECT.+ FROM find_namespaces_by_id\(\d+\)/
    else
      /\ASELECT.+FROM "namespaces" WHERE "namespaces"."id" = \d+/
    end
  end

  let(:additional_preloads) { [] }
  let(:groups) { [guest_group, private_maintainer_group, private_developer_group, public_maintainer_group] }
  let(:pristine_groups) { Group.where(id: groups) }

  shared_examples 'executes N matching DB queries' do |expected_query_count, query_method = nil|
    it 'executes the specified root_ancestor queries' do
      expect do
        pristine_groups.each do |group|
          root_ancestor = group.root_ancestor

          root_ancestor.public_send(query_method) if query_method.present?
        end
      end.to make_queries_matching(root_query_regex, expected_query_count)
    end

    it 'strong_memoizes the correct root_ancestor' do
      pristine_groups.each do |group|
        expected_parent_id = group.root_ancestor.id == group.id ? nil : group.root_ancestor.id

        expect(group.parent_id).to eq(expected_parent_id)
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
    described_class.new(pristine_groups, additional_preloads).execute
  end
end
