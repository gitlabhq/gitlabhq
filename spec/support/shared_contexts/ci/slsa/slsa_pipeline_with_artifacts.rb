# frozen_string_literal: true

RSpec.shared_context 'with build, pipeline and artifacts' do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be_with_reload(:group) { create_default(:group, :allow_runner_registration_token) }
  let_it_be_with_reload(:project) { create_default(:project, :public, :repository, group: group) }
  let_it_be_with_reload(:pipeline) do
    create_default(
      :ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let(:build) do
    create(:ci_build, :slsa_artifacts, :finished, runner_manager: runner_manager, pipeline: pipeline, stage: "build")
  end

  let_it_be(:runner, freeze: false) { create(:ci_runner, :hosted_runner) }
  let_it_be(:runner_manager, freeze: false) { create(:ci_runner_machine, runner: runner) }
  let_it_be(:id_token) { "jwt.jwt.KMUFsIDTnFmyG3nMiGM6H9FNFUROf3wh7SmqJp-QV30" }

  let(:attest_method) { nil }

  let(:yaml_variables) do
    variables = [
      # Temporary mechanism to prevent running in test suite while UX is discused.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/547903#note_2654845642
      { key: 'ATTEST_BUILD_ARTIFACTS', value: 'true', public: true }
    ]

    variables.append({ key: 'ATTEST_METHOD', value: attest_method, public: true }) if attest_method

    variables
  end

  before do
    stub_ci_job_definition(build, yaml_variables: yaml_variables) if build
  end
end
