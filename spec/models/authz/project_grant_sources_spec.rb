# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::ProjectGrantSources, :request_store, feature_category: :permissions do
  let_it_be(:root) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:invited) { create(:group) }
  let_it_be(:shared_with) { create(:group) }

  before_all do
    create(:project_group_link, project: project, group: invited, group_access: Gitlab::Access::REPORTER)
    create(:group_group_link, :developer, shared_group: root, shared_with_group: shared_with)
  end

  subject(:sources) { described_class.new }

  describe '#project_rows' do
    it 'returns the namespace details of each project' do
      expect(sources.project_rows([project.id])).to eq(
        project.id => {
          namespace_type: 'Group',
          owner_id: nil,
          traversal_ids: subgroup.traversal_ids,
          share_with_group_lock: false
        }
      )
    end

    it 'accepts records, IDs and relations' do
      expect(sources.project_rows([project]).keys).to contain_exactly(project.id)
      expect(sources.project_rows([Project.find(project.id)]).keys).to contain_exactly(project.id)
      expect(sources.project_rows(Project.id_in(project.id)).keys).to contain_exactly(project.id)
    end

    it 'builds the same rows from loaded namespaces as from the query, without querying' do
      personal_project = create(:project, namespace: create(:user, :with_namespace).namespace)
      ids = [project.id, personal_project.id]
      queried = described_class.new.project_rows(ids)
      Gitlab::SafeRequestStore.clear!
      loaded = Project.preload(:group, :namespace).id_in(ids).to_a

      expect { expect(described_class.new.project_rows(loaded)).to eq(queried) }.not_to exceed_query_limit(0)
      expect(queried[personal_project.id])
        .to include(namespace_type: 'User', traversal_ids: [personal_project.namespace_id])
    end

    it 'skips projects that are not saved' do
      expect(sources.project_rows([build(:project, group: subgroup), build(:project)])).to eq({})
    end

    it 'does not query projects again, including IDs that do not exist' do
      sources.project_rows([project.id, non_existing_record_id])

      expect { described_class.new.project_rows([project.id, non_existing_record_id]) }.not_to exceed_query_limit(0)
      expect(described_class.new.project_rows([non_existing_record_id])).to eq({})
    end
  end

  describe '#project_shares' do
    it 'returns each project share with the invited group hierarchy, and no shares for other projects' do
      other_project = create(:project)

      expect(sources.project_shares([project.id, other_project.id])).to eq(
        project.id => [{ group_access: Gitlab::Access::REPORTER, member_role_id: nil,
                         group_traversal_ids: invited.traversal_ids }],
        other_project.id => []
      )
    end
  end

  describe '#hierarchy_group_ids' do
    it 'includes the project hierarchy and each invited group hierarchy' do
      rows = sources.project_rows([project.id])

      expect(sources.hierarchy_group_ids(rows, sources.project_shares([project.id])))
        .to contain_exactly(root.id, subgroup.id, invited.id)
    end
  end

  describe '#group_shares and #shares_into' do
    it 'returns the shares into each group' do
      expect(sources.group_shares([root.id, subgroup.id])).to eq(
        root.id => [{ shared_with_group_id: shared_with.id, group_access: Gitlab::Access::DEVELOPER,
                      member_role_id: nil }],
        subgroup.id => []
      )
    end

    it 'loads the shares of a group not loaded yet' do
      expect(sources.shares_into(root.id)).to contain_exactly(a_hash_including(shared_with_group_id: shared_with.id))
    end

    it 'reuses the shares for the rest of the request' do
      sources.group_shares([root.id])

      expect { described_class.new.shares_into(root.id) }.not_to exceed_query_limit(0)
    end
  end
end
