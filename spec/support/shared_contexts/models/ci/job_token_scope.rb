# frozen_string_literal: true

RSpec.shared_context 'with a project in each allowlist' do
  let_it_be(:outbound_allowlist_project, freeze: false) do
    create_project_in_allowlist(source_project, direction: :outbound)
  end

  include_context 'with inaccessible projects'
end

RSpec.shared_context 'with accessible and inaccessible projects' do
  let_it_be(:outbound_allowlist_project, freeze: false) do
    create_project_in_allowlist(source_project, direction: :outbound)
  end

  let_it_be(:inbound_accessible_project, freeze: false) { create_inbound_accessible_project(source_project) }
  let_it_be(:fully_accessible_project, freeze: false) { create_inbound_and_outbound_accessible_project(source_project) }

  include_context 'with inaccessible projects'
end

RSpec.shared_context 'with projects that are with and without groups added in allowlist' do
  let_it_be(:project_with_target_project_group_in_allowlist, freeze: false) do
    create_project_with_group_allowlist(target_project)
  end

  let_it_be(:project_wo_target_project_group_in_allowlist, freeze: false) { create_project_without_group_allowlist }
end

RSpec.shared_context 'with inaccessible projects' do
  let_it_be(:inbound_allowlist_project, freeze: false) do
    create_project_in_allowlist(source_project, direction: :inbound)
  end

  include_context 'with unscoped projects'
end

RSpec.shared_context 'with unscoped projects' do
  let_it_be(:unscoped_project1, freeze: false) { create(:project) }
  let_it_be(:unscoped_project2, freeze: false) { create(:project) }
  let_it_be(:unscoped_public_project, freeze: false) { create(:project, :public) }

  let_it_be(:link_out_of_scope, freeze: false) do
    create(:ci_job_token_project_scope_link, target_project: unscoped_project1)
  end
end
