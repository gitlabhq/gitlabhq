# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::ProjectRootAncestorPreloader, feature_category: :system_access do
  let_it_be(:root_parent1) { create(:group, :private, name: 'root-1', path: 'root-1') }
  let_it_be(:root_parent2) { create(:group, name: 'root-2', path: 'root-2') }
  let_it_be(:guest_project) { create(:project, name: 'public guest', path: 'public-guest') }
  let_it_be(:private_maintainer_project) do
    create(:project, :private, name: 'b private maintainer', path: 'b-private-maintainer', namespace: root_parent1)
  end

  let_it_be(:private_developer_project) do
    create(:project, :private, name: 'c public developer', path: 'c-public-developer')
  end

  let_it_be(:public_maintainer_project) do
    create(:project, name: 'a public maintainer', path: 'a-public-maintainer', namespace: root_parent2)
  end

  let(:root_query_regex) do
    if Feature.enabled?(:use_sql_functions_for_primary_key_lookups, Feature.current_request)
      /\ASELECT.+ FROM find_namespaces_by_id\(\d+\)/
    else
      /\ASELECT.+FROM "namespaces" WHERE "namespaces"."id" = \d+/
    end
  end

  let(:additional_preloads) { [] }
  let(:projects) { [guest_project, private_maintainer_project, private_developer_project, public_maintainer_project] }
  let(:pristine_projects) { Project.where(id: projects) }

  shared_examples 'executes N matching DB queries' do |expected_query_count, query_method = nil|
    it 'executes the specified root_ancestor queries' do
      expect do
        pristine_projects.each do |project|
          root_ancestor = project.root_ancestor

          root_ancestor.public_send(query_method) if query_method.present?
        end
      end.to make_queries_matching(root_query_regex, expected_query_count)
    end

    it 'strong_memoizes the correct root_ancestor' do
      pristine_projects.each do |project|
        preloaded_parent_id = project.root_ancestor&.id

        expect(preloaded_parent_id).to eq(project.parent_id)
      end
    end
  end

  context 'when the preloader is used' do
    context 'when no additional preloads are provided' do
      before do
        preload_ancestors(:group)
      end

      it_behaves_like 'executes N matching DB queries', 0
    end

    context 'when additional preloads are provided' do
      let(:additional_preloads) { [:route] }
      let(:root_query_regex) { /\ASELECT.+FROM "routes" WHERE "routes"."source_id" = \d+/ }

      before do
        preload_ancestors
      end

      it_behaves_like 'executes N matching DB queries', 0, :full_path
    end

    context 'when projects are an array and not an ActiveRecord::Relation' do
      before do
        described_class.new(projects, :namespace, additional_preloads).execute
      end

      it_behaves_like 'executes N matching DB queries', 4
    end
  end

  context 'when the preloader is not used' do
    it_behaves_like 'executes N matching DB queries', 4
  end

  context 'when using a :group sti name and passing projects in a user namespace' do
    let(:projects) { [private_developer_project] }
    let(:additional_preloads) { [:ip_restrictions, :saml_provider] }

    it 'does not load a nil value for root_ancestor' do
      preload_ancestors(:group)

      expect(pristine_projects.first.root_ancestor).to eq(private_developer_project.root_ancestor)
    end
  end

  private

  def preload_ancestors(namespace_sti_name = :namespace)
    described_class.new(pristine_projects, namespace_sti_name, additional_preloads).execute
  end
end
