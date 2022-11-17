# frozen_string_literal: true

RSpec.shared_context 'importable repositories' do
  let_it_be(:valid_container_repository) { create(:container_repository, created_at: 2.days.ago, migration_plan: 'free') }
  let_it_be(:valid_container_repository2) { create(:container_repository, created_at: 1.year.ago, migration_plan: 'free') }
  let_it_be(:importing_container_repository) { create(:container_repository, :importing, created_at: 2.days.ago, migration_plan: 'free') }
  let_it_be(:new_container_repository) { create(:container_repository, migration_plan: 'free') }

  let_it_be(:denied_root_group) { create(:group) }
  let_it_be(:denied_group) { create(:group, parent_id: denied_root_group.id) }
  let_it_be(:denied_project) { create(:project, group: denied_group) }
  let_it_be(:denied_container_repository) { create(:container_repository, project: denied_project, created_at: 2.days.ago) }

  before do
    stub_application_setting(container_registry_import_created_before: 1.day.ago)
    stub_feature_flags(
      container_registry_migration_limit_gitlab_org: false,
      container_registry_migration_phase2_all_plans: false
    )

    Feature::FlipperGate.create!(
      feature_key: 'container_registry_phase_2_deny_list',
      key: 'actors',
      value: "Group:#{denied_root_group.id}"
    )
  end
end
