# frozen_string_literal: true

RSpec.shared_context 'with scoped projects' do
  let_it_be(:inbound_scoped_project) { create_scoped_project(source_project, direction: :inbound) }
  let_it_be(:outbound_scoped_project) { create_scoped_project(source_project, direction: :outbound) }
  let_it_be(:unscoped_project1) { create(:project) }
  let_it_be(:unscoped_project2) { create(:project) }

  let_it_be(:link_out_of_scope) { create(:ci_job_token_project_scope_link, target_project: unscoped_project1) }

  def create_scoped_project(source_project, direction:)
    create(:project).tap do |scoped_project|
      create(
        :ci_job_token_project_scope_link,
        source_project: source_project,
        target_project: scoped_project,
        direction: direction
      )
    end
  end
end
