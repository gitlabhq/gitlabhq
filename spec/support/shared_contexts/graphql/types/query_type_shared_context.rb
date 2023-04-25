# frozen_string_literal: true

RSpec.shared_context 'with FOSS query type fields' do
  # extracted these fields into a shared variable so that we can define FOSS fields once and use them on EE spec as well
  let(:expected_foss_fields) do
    [
      :board_list,
      :ci_application_settings,
      :ci_config,
      :ci_pipeline_stage,
      :ci_variables,
      :container_repository,
      :current_user,
      :design_management,
      :echo,
      :gitpod_enabled,
      :group,
      :groups,
      :issue,
      :issues,
      :jobs,
      :merge_request,
      :metadata,
      :milestone,
      :namespace,
      :note,
      :package,
      :project,
      :projects,
      :query_complexity,
      :runner,
      :runner_platforms,
      :runner_setup,
      :runners,
      :snippets,
      :synthetic_note,
      :timelogs,
      :todo,
      :topics,
      :usage_trends_measurements,
      :user,
      :users,
      :work_item
    ]
  end
end
