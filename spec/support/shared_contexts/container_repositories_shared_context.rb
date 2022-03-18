# frozen_string_literal: true

RSpec.shared_context 'importable repositories' do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent_id: root_group.id) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:valid_container_repository) { create(:container_repository, project: project, created_at: 2.days.ago) }
  let_it_be(:valid_container_repository2) { create(:container_repository, project: project, created_at: 1.year.ago) }
  let_it_be(:importing_container_repository) { create(:container_repository, :importing, project: project, created_at: 2.days.ago) }
  let_it_be(:new_container_repository) { create(:container_repository, project: project) }

  let_it_be(:denied_root_group) { create(:group) }
  let_it_be(:denied_group) { create(:group, parent_id: denied_root_group.id) }
  let_it_be(:denied_project) { create(:project, group: denied_group) }
  let_it_be(:denied_container_repository) { create(:container_repository, project: denied_project, created_at: 2.days.ago) }

  before do
    stub_application_setting(container_registry_import_created_before: 1.day.ago)
    stub_feature_flags(
      container_registry_phase_2_deny_list: false,
      container_registry_migration_limit_gitlab_org: false
    )

    Feature::FlipperGate.create!(
      feature_key: 'container_registry_phase_2_deny_list',
      key: 'actors',
      value: "Group:#{denied_root_group.id}"
    )
  end
end
