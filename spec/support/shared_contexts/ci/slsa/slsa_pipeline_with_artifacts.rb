# frozen_string_literal: true

RSpec.shared_context 'with build, pipeline and artifacts' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create_default(:group, :allow_runner_registration_token) }
  let_it_be(:project, reload: true) { create_default(:project, :repository, group: group) }
  let_it_be(:pipeline, reload: true) do
    create_default(
      :ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let(:build) do
    create(:ci_build, :slsa_artifacts, :finished, runner_manager: runner_manager, pipeline: pipeline)
  end

  let_it_be(:runner) { create(:ci_runner, :hosted_runner) }
  let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner) }

  # Temporary mechanism to prevent running in test suite while UX is discused.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/547903#note_2654845642
  let(:yaml_variables) { [{ key: 'GENERATE_PROVENANCE', value: 'true', public: true }] }

  before do
    allow(build).to receive(:yaml_variables).and_return(yaml_variables)
  end
end
