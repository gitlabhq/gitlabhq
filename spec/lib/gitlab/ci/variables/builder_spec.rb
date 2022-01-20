# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:user) { project.owner }
  let_it_be(:job) do
    create(:ci_build,
      pipeline: pipeline,
      user: user,
      yaml_variables: [{ key: 'YAML_VARIABLE', value: 'value' }]
    )
  end

  let(:builder) { described_class.new(pipeline) }

  describe '#scoped_variables' do
    let(:environment) { job.expanded_environment_name }
    let(:dependencies) { true }
    let(:predefined_variables) do
      [
        { key: 'CI_JOB_NAME',
          value: job.name },
        { key: 'CI_JOB_STAGE',
          value: job.stage },
        { key: 'CI_NODE_TOTAL',
          value: '1' },
        { key: 'CI_BUILD_NAME',
          value: job.name },
        { key: 'CI_BUILD_STAGE',
          value: job.stage },
        { key: 'CI',
          value: 'true' },
        { key: 'GITLAB_CI',
          value: 'true' },
        { key: 'CI_SERVER_URL',
          value: Gitlab.config.gitlab.url },
        { key: 'CI_SERVER_HOST',
          value: Gitlab.config.gitlab.host },
        { key: 'CI_SERVER_PORT',
          value: Gitlab.config.gitlab.port.to_s },
        { key: 'CI_SERVER_PROTOCOL',
          value: Gitlab.config.gitlab.protocol },
        { key: 'CI_SERVER_NAME',
          value: 'GitLab' },
        { key: 'CI_SERVER_VERSION',
          value: Gitlab::VERSION },
        { key: 'CI_SERVER_VERSION_MAJOR',
          value: Gitlab.version_info.major.to_s },
        { key: 'CI_SERVER_VERSION_MINOR',
          value: Gitlab.version_info.minor.to_s },
        { key: 'CI_SERVER_VERSION_PATCH',
          value: Gitlab.version_info.patch.to_s },
        { key: 'CI_SERVER_REVISION',
          value: Gitlab.revision },
        { key: 'GITLAB_FEATURES',
          value: project.licensed_features.join(',') },
        { key: 'CI_PROJECT_ID',
          value: project.id.to_s },
        { key: 'CI_PROJECT_NAME',
          value: project.path },
        { key: 'CI_PROJECT_TITLE',
          value: project.title },
        { key: 'CI_PROJECT_PATH',
          value: project.full_path },
        { key: 'CI_PROJECT_PATH_SLUG',
          value: project.full_path_slug },
        { key: 'CI_PROJECT_NAMESPACE',
          value: project.namespace.full_path },
        { key: 'CI_PROJECT_ROOT_NAMESPACE',
          value: project.namespace.root_ancestor.path },
        { key: 'CI_PROJECT_URL',
          value: project.web_url },
        { key: 'CI_PROJECT_VISIBILITY',
          value: "private" },
        { key: 'CI_PROJECT_REPOSITORY_LANGUAGES',
          value: project.repository_languages.map(&:name).join(',').downcase },
        { key: 'CI_PROJECT_CLASSIFICATION_LABEL',
          value: project.external_authorization_classification_label },
        { key: 'CI_DEFAULT_BRANCH',
          value: project.default_branch },
        { key: 'CI_CONFIG_PATH',
          value: project.ci_config_path_or_default },
        { key: 'CI_PAGES_DOMAIN',
          value: Gitlab.config.pages.host },
        { key: 'CI_PAGES_URL',
          value: project.pages_url },
        { key: 'CI_API_V4_URL',
          value: API::Helpers::Version.new('v4').root_url },
        { key: 'CI_PIPELINE_IID',
          value: pipeline.iid.to_s },
        { key: 'CI_PIPELINE_SOURCE',
          value: pipeline.source },
        { key: 'CI_PIPELINE_CREATED_AT',
          value: pipeline.created_at.iso8601 },
        { key: 'CI_COMMIT_SHA',
          value: job.sha },
        { key: 'CI_COMMIT_SHORT_SHA',
          value: job.short_sha },
        { key: 'CI_COMMIT_BEFORE_SHA',
          value: job.before_sha },
        { key: 'CI_COMMIT_REF_NAME',
          value: job.ref },
        { key: 'CI_COMMIT_REF_SLUG',
          value: job.ref_slug },
        { key: 'CI_COMMIT_BRANCH',
          value: job.ref },
        { key: 'CI_COMMIT_MESSAGE',
          value: pipeline.git_commit_message },
        { key: 'CI_COMMIT_TITLE',
          value: pipeline.git_commit_title },
        { key: 'CI_COMMIT_DESCRIPTION',
          value: pipeline.git_commit_description },
        { key: 'CI_COMMIT_REF_PROTECTED',
          value: (!!pipeline.protected_ref?).to_s },
        { key: 'CI_COMMIT_TIMESTAMP',
          value: pipeline.git_commit_timestamp },
        { key: 'CI_COMMIT_AUTHOR',
          value: pipeline.git_author_full_text },
        { key: 'CI_BUILD_REF',
          value: job.sha },
        { key: 'CI_BUILD_BEFORE_SHA',
          value: job.before_sha },
        { key: 'CI_BUILD_REF_NAME',
          value: job.ref },
        { key: 'CI_BUILD_REF_SLUG',
          value: job.ref_slug },
        { key: 'YAML_VARIABLE',
          value: 'value' },
        { key: 'GITLAB_USER_ID',
          value: user.id.to_s },
        { key: 'GITLAB_USER_EMAIL',
         value: user.email },
        { key: 'GITLAB_USER_LOGIN',
         value: user.username },
        { key: 'GITLAB_USER_NAME',
         value: user.name }
      ].map { |var| var.merge(public: true, masked: false) }
    end

    subject { builder.scoped_variables(job, environment: environment, dependencies: dependencies) }

    it { is_expected.to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it { expect(subject.to_runner_variables).to eq(predefined_variables) }

    context 'variables ordering' do
      def var(name, value)
        { key: name, value: value.to_s, public: true, masked: false }
      end

      before do
        allow(builder).to receive(:predefined_variables) { [var('A', 1), var('B', 1)] }
        allow(project).to receive(:predefined_variables) { [var('B', 2), var('C', 2)] }
        allow(pipeline).to receive(:predefined_variables) { [var('C', 3), var('D', 3)] }
        allow(job).to receive(:runner) { double(predefined_variables: [var('D', 4), var('E', 4)]) }
        allow(builder).to receive(:kubernetes_variables) { [var('E', 5), var('F', 5)] }
        allow(builder).to receive(:deployment_variables) { [var('F', 6), var('G', 6)] }
        allow(job).to receive(:yaml_variables) { [var('G', 7), var('H', 7)] }
        allow(builder).to receive(:user_variables) { [var('H', 8), var('I', 8)] }
        allow(job).to receive(:dependency_variables) { [var('I', 9), var('J', 9)] }
        allow(builder).to receive(:secret_instance_variables) { [var('J', 10), var('K', 10)] }
        allow(builder).to receive(:secret_group_variables) { [var('K', 11), var('L', 11)] }
        allow(builder).to receive(:secret_project_variables) { [var('L', 12), var('M', 12)] }
        allow(job).to receive(:trigger_request) { double(user_variables: [var('M', 13), var('N', 13)]) }
        allow(pipeline).to receive(:variables) { [var('N', 14), var('O', 14)] }
        allow(pipeline).to receive(:pipeline_schedule) { double(job_variables: [var('O', 15), var('P', 15)]) }
      end

      it 'returns variables in order depending on resource hierarchy' do
        expect(subject.to_runner_variables).to eq(
          [var('A', 1), var('B', 1),
           var('B', 2), var('C', 2),
           var('C', 3), var('D', 3),
           var('D', 4), var('E', 4),
           var('E', 5), var('F', 5),
           var('F', 6), var('G', 6),
           var('G', 7), var('H', 7),
           var('H', 8), var('I', 8),
           var('I', 9), var('J', 9),
           var('J', 10), var('K', 10),
           var('K', 11), var('L', 11),
           var('L', 12), var('M', 12),
           var('M', 13), var('N', 13),
           var('N', 14), var('O', 14),
           var('O', 15), var('P', 15)])
      end

      it 'overrides duplicate keys depending on resource hierarchy' do
        expect(subject.to_hash).to match(
          'A' => '1', 'B' => '2',
          'C' => '3', 'D' => '4',
          'E' => '5', 'F' => '6',
          'G' => '7', 'H' => '8',
          'I' => '9', 'J' => '10',
          'K' => '11', 'L' => '12',
          'M' => '13', 'N' => '14',
          'O' => '15', 'P' => '15')
      end
    end
  end
end
