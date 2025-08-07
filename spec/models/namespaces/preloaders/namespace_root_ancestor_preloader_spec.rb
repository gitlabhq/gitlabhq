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

  context 'when namespaces have no root ancestor in query results' do
    it 'safely handles namespaces without root ancestors' do
      # Create a preloader with an empty namespaces array to simulate
      # the scenario where the root query returns no matching records
      expect { described_class.new([], additional_preloads).execute }.not_to raise_error
    end

    it 'handles case where root_ancestors_by_id lookup returns nil' do
      namespace = build(:namespace, id: non_existing_record_id)
      allow(namespace).to receive(:id).and_return(non_existing_record_id)

      preloader = described_class.new([namespace], additional_preloads)

      # Mock the Namespace query to return empty results, simulating the
      # scenario where no root ancestor is found for the namespace
      empty_relation = Namespace.none
      allow(Namespace).to receive(:joins).and_return(empty_relation)
      allow(empty_relation).to receive_messages(
        select: empty_relation,
        preload: empty_relation,
        group_by: {}
      )

      expect { preloader.execute }.not_to raise_error

      # Verify that the namespace's root_ancestor instance variable was not set
      expect(namespace.instance_variable_get(:@root_ancestor)).to be_nil
    end

    it 'logs orphaned namespace with structured payload when root ancestor is not found' do
      orphaned_namespace = build(:namespace,
        id: non_existing_record_id,
        path: 'orphaned-namespace',
        type: 'Group',
        traversal_ids: [123, 456]
      )

      preloader = described_class.new([orphaned_namespace], additional_preloads)

      # Mock the Namespace query to return empty results
      empty_relation = Namespace.none
      allow(Namespace).to receive(:joins).and_return(empty_relation)
      allow(empty_relation).to receive_messages(
        select: empty_relation,
        preload: empty_relation,
        group_by: {}
      )

      expected_payload = {
        'class' => 'Namespaces::Preloaders::NamespaceRootAncestorPreloader',
        'message' => 'Orphaned namespace detected. Unable to find root ancestor',
        'namespace_id' => non_existing_record_id,
        'namespace_type' => 'Group',
        'namespace_path' => 'orphaned-namespace',
        'traversal_ids' => [123, 456]
      }

      expect(Gitlab::AppLogger).to receive(:warn).with(expected_payload)

      preloader.execute
    end

    context 'when multiple orphaned namespaces exist' do
      it 'logs each orphaned namespace separately' do
        orphaned_namespace1 = build(:namespace,
          id: 9999,
          path: 'orphaned-1',
          type: 'Group',
          traversal_ids: [111]
        )

        orphaned_namespace2 = build(:namespace,
          id: 8888,
          path: 'orphaned-2',
          type: 'Project',
          traversal_ids: [222]
        )

        preloader = described_class.new([orphaned_namespace1, orphaned_namespace2], additional_preloads)

        # Mock the Namespace query to return empty results
        empty_relation = Namespace.none
        allow(Namespace).to receive(:joins).and_return(empty_relation)
        allow(empty_relation).to receive_messages(
          select: empty_relation,
          preload: empty_relation,
          group_by: {}
        )

        expect(Gitlab::AppLogger).to receive(:warn).twice

        preloader.execute
      end
    end
  end

  def preload_ancestors
    described_class.new(pristine_namespaces, additional_preloads).execute
  end
end
