# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder, :clean_gitlab_redis_cache, feature_category: :ci_variables do
  include Ci::TemplateHelpers
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:job) do
    create(:ci_build,
      :with_deployment,
      name: 'rspec:test 1',
      pipeline: pipeline,
      user: user,
      yaml_variables: [{ key: 'YAML_VARIABLE', value: 'value' }],
      environment: 'review/$CI_COMMIT_REF_NAME',
      options: {
        environment: {
          name: 'review/$CI_COMMIT_REF_NAME',
          action: 'prepare',
          deployment_tier: 'testing',
          url: 'https://gitlab.com'
        }
      }
    )
  end

  let(:predefined_project_vars) do
    [
      { key: 'CI',
        value: 'true' },
      { key: 'GITLAB_CI',
        value: 'true' },
      { key: 'CI_SERVER_FQDN',
        value: Gitlab.config.gitlab_ci.server_fqdn },
      { key: 'CI_SERVER_URL',
        value: Gitlab.config.gitlab.url },
      { key: 'CI_SERVER_HOST',
        value: Gitlab.config.gitlab.host },
      { key: 'CI_SERVER_PORT',
        value: Gitlab.config.gitlab.port.to_s },
      { key: 'CI_SERVER_PROTOCOL',
        value: Gitlab.config.gitlab.protocol },
      { key: 'CI_SERVER_SHELL_SSH_HOST',
        value: Gitlab.config.gitlab_shell.ssh_host.to_s },
      { key: 'CI_SERVER_SHELL_SSH_PORT',
        value: Gitlab.config.gitlab_shell.ssh_port.to_s },
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
      { key: 'CI_PROJECT_DESCRIPTION',
        value: project.description },
      { key: 'CI_PROJECT_PATH',
        value: project.full_path },
      { key: 'CI_PROJECT_PATH_SLUG',
        value: project.full_path_slug },
      { key: 'CI_PROJECT_NAMESPACE',
        value: project.namespace.full_path },
      { key: 'CI_PROJECT_NAMESPACE_ID',
        value: project.namespace.id.to_s },
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
        value: Gitlab::Pages::UrlBuilder.new(project).pages_url },
      { key: 'CI_API_V4_URL',
        value: API::Helpers::Version.new('v4').root_url },
      { key: 'CI_API_GRAPHQL_URL',
        value: Gitlab::Routing.url_helpers.api_graphql_url },
      { key: 'CI_TEMPLATE_REGISTRY_HOST',
        value: template_registry_host }
    ]
  end

  let(:predefined_user_vars) do
    [
      { key: 'GITLAB_USER_ID',
        value: user.id.to_s },
      { key: 'GITLAB_USER_EMAIL',
        value: user.email },
      { key: 'GITLAB_USER_LOGIN',
        value: user.username },
      { key: 'GITLAB_USER_NAME',
        value: user.name }
    ]
  end

  let(:builder) { described_class.new(pipeline) }

  before do
    stub_feature_flags(fix_pages_ci_variables: false)
  end

  describe '#scoped_variables' do
    let(:environment_name) { job.expanded_environment_name }
    let(:dependencies) { true }
    let(:predefined_variables) do
      (
        [
          { key: 'CI_JOB_NAME',
            value: 'rspec:test 1' },
          { key: 'CI_JOB_NAME_SLUG',
            value: 'rspec-test-1' },
          { key: 'CI_JOB_STAGE',
            value: job.stage_name },
          { key: 'CI_NODE_TOTAL',
            value: '1' },
          { key: 'CI_ENVIRONMENT_NAME',
            value: 'review/master' },
          { key: 'CI_ENVIRONMENT_ACTION',
            value: 'prepare' },
          { key: 'CI_ENVIRONMENT_TIER',
            value: 'testing' },
          { key: 'CI_ENVIRONMENT_URL',
            value: 'https://gitlab.com' }
        ] + predefined_project_vars + [
          { key: 'CI_PIPELINE_IID',
            value: pipeline.iid.to_s },
          { key: 'CI_PIPELINE_SOURCE',
            value: pipeline.source },
          { key: 'CI_PIPELINE_CREATED_AT',
            value: pipeline.created_at.iso8601 },
          { key: 'CI_PIPELINE_NAME',
            value: pipeline.name },
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
          { key: 'YAML_VARIABLE',
            value: 'value' }
        ] + predefined_user_vars
      ).map { |var| var.merge(public: true, masked: false) }
    end

    subject { builder.scoped_variables(job, environment: environment_name, dependencies: dependencies) }

    it { is_expected.to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it { expect(subject.to_runner_variables).to eq(predefined_variables) }

    context 'variables ordering' do
      def var(name, value)
        { key: name, value: value.to_s, public: true, masked: false }
      end

      before do
        pipeline_variables_builder = double(
          ::Gitlab::Ci::Variables::Builder::Pipeline,
          predefined_variables: [var('C', 3), var('D', 3)]
        )

        allow(builder).to receive(:predefined_variables) { [var('A', 1), var('B', 1)] }
        allow(pipeline.project).to receive(:predefined_variables) { [var('B', 2), var('C', 2)] }
        allow(builder).to receive(:pipeline_variables_builder) { pipeline_variables_builder }
        allow(pipeline).to receive(:predefined_variables) { [var('C', 3), var('D', 3)] }
        allow(job).to receive(:runner) { double(predefined_variables: [var('D', 4), var('E', 4)]) }
        allow(builder).to receive(:kubernetes_variables) { [var('E', 5), var('F', 5)] }
        allow(job).to receive(:yaml_variables) { [var('G', 7), var('H', 7)] }
        allow(builder).to receive(:user_variables) { [var('H', 8), var('I', 8)] }
        allow(job).to receive(:dependency_variables) { [var('I', 9), var('J', 9)] }
        allow(builder).to receive(:secret_instance_variables) { [var('J', 10), var('K', 10)] }
        allow(builder).to receive(:secret_group_variables) { [var('K', 11), var('L', 11)] }
        allow(builder).to receive(:secret_project_variables) { [var('L', 12), var('M', 12)] }
        allow(pipeline).to receive(:variables) { [var('M', 13), var('N', 13)] }
        allow(pipeline).to receive(:pipeline_schedule) { double(job_variables: [var('N', 14), var('O', 14)]) }
        allow(builder).to receive(:release_variables) { [var('P', 15), var('Q', 15)] }
      end

      it 'returns variables in order depending on resource hierarchy' do
        expect(subject.to_runner_variables).to eq(
          [var('A', 1), var('B', 1),
           var('B', 2), var('C', 2),
           var('C', 3), var('D', 3),
           var('D', 4), var('E', 4),
           var('E', 5), var('F', 5),
           var('G', 7), var('H', 7),
           var('H', 8), var('I', 8),
           var('I', 9), var('J', 9),
           var('J', 10), var('K', 10),
           var('K', 11), var('L', 11),
           var('L', 12), var('M', 12),
           var('M', 13), var('N', 13),
           var('N', 14), var('O', 14),
           var('P', 15), var('Q', 15)])
      end

      it 'overrides duplicate keys depending on resource hierarchy' do
        expect(subject.to_hash).to match(
          'A' => '1', 'B' => '2',
          'C' => '3', 'D' => '4',
          'E' => '5', 'F' => '5',
          'G' => '7', 'H' => '8',
          'I' => '9', 'J' => '10',
          'K' => '11', 'L' => '12',
          'M' => '13', 'N' => '14',
          'O' => '14', 'P' => '15',
          'Q' => '15')
      end
    end

    context 'with schedule variables' do
      let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project) }
      let_it_be(:schedule_variable) { create(:ci_pipeline_schedule_variable, pipeline_schedule: schedule) }

      before do
        pipeline.update!(pipeline_schedule_id: schedule.id)
      end

      it 'includes schedule variables' do
        expect(subject.to_runner_variables)
          .to include(a_hash_including(key: schedule_variable.key, value: schedule_variable.value))
      end
    end

    context 'with release variables' do
      let(:release_description_key) { 'CI_RELEASE_DESCRIPTION' }

      let_it_be(:tag) { project.repository.tags.first }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, tag: true, ref: tag.name) }
      let_it_be(:release) { create(:release, tag: tag.name, project: project) }

      it 'includes release variables' do
        expect(subject.to_hash).to include(release_description_key => release.description)
      end

      context 'when there is no release' do
        let_it_be(:pipeline) { create(:ci_pipeline, project: project, tag: false, ref: 'master') }
        let(:release) { nil }

        it 'does not include release variables' do
          expect(subject.to_hash).not_to have_key(release_description_key)
        end
      end
    end

    context 'when environment tier and url is not passed' do
      let(:job2) do
        create(:ci_build,
          name: 'rspec:test 2',
          pipeline: pipeline,
          user: user,
          environment: 'test/$CI_COMMIT_REF_NAME',
          options: {
            environment: {
              name: 'test/$CI_COMMIT_REF_NAME',
              action: 'prepare'
            }
          }
        )
      end

      subject { builder.scoped_variables(job2, environment: environment_name, dependencies: dependencies) }

      it 'returns CI_ENVIRONMENT_TIER as nil and not return CI_ENVIRONMENT_URL' do
        expect(subject.to_hash).to include('CI_ENVIRONMENT_TIER' => nil)
        expect(subject.to_hash).not_to have_key('CI_ENVIRONMENT_URL')
      end

      context 'when there is an existing environment with the same name' do
        let!(:environment) do
          create(:environment, name: 'test/master', external_url: 'https://hello.test', project: project)
        end

        it 'fetches CI_ENVIRONMENT_TIER and CI_ENVIRONMENT_URL from an old environment' do
          expect(subject.to_hash).to include('CI_ENVIRONMENT_TIER' => 'testing')
          expect(subject.to_hash).to include('CI_ENVIRONMENT_URL' => 'https://hello.test')
        end
      end
    end
  end

  describe '#scoped_variables_for_pipeline_seed' do
    let(:environment_name) { 'test/master' }
    let(:kubernetes_namespace) { nil }
    let(:extra_attributes) { {} }
    let(:trigger_request) { nil }
    let(:yaml_variables) { [{ key: 'YAML_VARIABLE', value: 'value' }] }

    let(:predefined_variables) do
      (
        [
          { key: 'CI_JOB_NAME',
            value: 'rspec:test 2' },
          { key: 'CI_JOB_NAME_SLUG',
            value: 'rspec-test-2' },
          { key: 'CI_JOB_STAGE',
            value: 'test' },
          { key: 'CI_NODE_TOTAL',
            value: '1' },
          { key: 'CI_ENVIRONMENT_NAME',
            value: 'test/master' },
          { key: 'CI_ENVIRONMENT_ACTION',
            value: 'prepare' },
          { key: 'CI_ENVIRONMENT_TIER',
            value: 'testing' },
          { key: 'CI_ENVIRONMENT_URL',
            value: 'https://gitlab.com' }
        ] + predefined_project_vars + [
          { key: 'CI_PIPELINE_IID',
            value: pipeline.iid.to_s },
          { key: 'CI_PIPELINE_SOURCE',
            value: pipeline.source },
          { key: 'CI_PIPELINE_CREATED_AT',
            value: nil },
          { key: 'CI_PIPELINE_NAME',
            value: pipeline.name },
          { key: 'CI_COMMIT_SHA',
            value: pipeline.sha },
          { key: 'CI_COMMIT_SHORT_SHA',
            value: pipeline.short_sha },
          { key: 'CI_COMMIT_BEFORE_SHA',
            value: pipeline.before_sha },
          { key: 'CI_COMMIT_REF_NAME',
            value: pipeline.ref },
          { key: 'CI_COMMIT_REF_SLUG',
            value: pipeline.ref },
          { key: 'CI_COMMIT_BRANCH',
            value: pipeline.ref },
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
          { key: 'YAML_VARIABLE',
            value: 'value' }
        ] + predefined_user_vars
      ).map { |var| var.merge(public: true, masked: false) }
    end

    let(:pipeline) { build(:ci_pipeline, project: project) }

    let(:job_attr) do
      {
        name: 'rspec:test 2',
        stage: 'test',
        yaml_variables: yaml_variables,
        options: {
          environment: {
            name: 'review/$CI_COMMIT_REF_NAME',
            action: 'prepare',
            deployment_tier: 'testing',
            url: 'https://gitlab.com'
          }
        },
        **extra_attributes
      }
    end

    subject do
      builder.scoped_variables_for_pipeline_seed(
        job_attr,
        environment: environment_name,
        kubernetes_namespace: kubernetes_namespace,
        user: user,
        trigger_request: trigger_request
      )
    end

    it { is_expected.to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it { expect(subject.to_runner_variables).to eq(predefined_variables) }

    context 'variables ordering' do
      def var(name, value)
        { key: name, value: value.to_s, public: true, masked: false }
      end

      let(:yaml_variables) { [var('G', 7), var('H', 7)] }

      before do
        pipeline_variables_builder = double(
          ::Gitlab::Ci::Variables::Builder::Pipeline,
          predefined_variables: [var('C', 3), var('D', 3)]
        )

        allow(builder).to receive(:predefined_variables_from_job_attr) { [var('A', 1), var('B', 1)] }
        allow(pipeline.project).to receive(:predefined_variables) { [var('B', 2), var('C', 2)] }
        allow(builder).to receive(:pipeline_variables_builder) { pipeline_variables_builder }
        allow(pipeline).to receive(:predefined_variables) { [var('C', 3), var('D', 3)] }
        allow(builder).to receive(:kubernetes_variables) { [var('E', 5), var('F', 5)] }
        allow(builder).to receive(:user_variables) { [var('H', 8), var('I', 8)] }
        allow(builder).to receive(:secret_instance_variables) { [var('J', 10), var('K', 10)] }
        allow(builder).to receive(:secret_group_variables) { [var('K', 11), var('L', 11)] }
        allow(builder).to receive(:secret_project_variables) { [var('L', 12), var('M', 12)] }
        allow(pipeline).to receive(:variables) { [var('M', 13), var('N', 13)] }
        allow(pipeline).to receive(:pipeline_schedule) { double(job_variables: [var('N', 14), var('O', 14)]) }
        allow(builder).to receive(:release_variables) { [var('P', 15), var('Q', 15)] }
      end

      it 'returns variables in order depending on resource hierarchy' do
        expect(subject.to_runner_variables).to eq(
          [var('A', 1), var('B', 1),
           var('B', 2), var('C', 2),
           var('C', 3), var('D', 3),
           var('E', 5), var('F', 5),
           var('G', 7), var('H', 7),
           var('H', 8), var('I', 8),
           var('J', 10), var('K', 10),
           var('K', 11), var('L', 11),
           var('L', 12), var('M', 12),
           var('M', 13), var('N', 13),
           var('N', 14), var('O', 14),
           var('P', 15), var('Q', 15)])
      end

      it 'overrides duplicate keys depending on resource hierarchy' do
        expect(subject.to_hash).to match(
          'A' => '1', 'B' => '2',
          'C' => '3', 'D' => '3',
          'E' => '5', 'F' => '5',
          'G' => '7', 'H' => '8',
          'I' => '8', 'J' => '10',
          'K' => '11', 'L' => '12',
          'M' => '13', 'N' => '14',
          'O' => '14', 'P' => '15',
          'Q' => '15')
      end
    end

    context 'with schedule variables' do
      let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project) }
      let_it_be(:schedule_variable) { create(:ci_pipeline_schedule_variable, pipeline_schedule: schedule) }

      before do
        pipeline.update!(pipeline_schedule_id: schedule.id)
      end

      it 'includes schedule variables' do
        expect(subject.to_runner_variables)
          .to include(a_hash_including(key: schedule_variable.key, value: schedule_variable.value))
      end
    end

    context 'with release variables' do
      let(:release_description_key) { 'CI_RELEASE_DESCRIPTION' }

      let_it_be(:tag) { project.repository.tags.first }
      let_it_be(:release) { create(:release, tag: tag.name, project: project) }
      let_it_be(:pipeline) { build(:ci_pipeline, project: project, tag: true, ref: tag.name) }

      it 'includes release variables' do
        expect(subject.to_hash).to include(release_description_key => release.description)
      end

      context 'when there is no release' do
        let_it_be(:pipeline) { build(:ci_pipeline, project: project, tag: false, ref: 'master') }
        let(:release) { nil }

        it 'does not include release variables' do
          expect(subject.to_hash).not_to have_key(release_description_key)
        end
      end
    end

    ::Ci::Processable::ACTIONABLE_WHEN.each do |when_attr|
      context "when job is #{when_attr}" do
        let(:extra_attributes) { { when: when_attr } }

        it 'includes CI_JOB_MANUAL as true' do
          expect(subject.to_hash).to include('CI_JOB_MANUAL' => 'true')
        end
      end
    end

    context 'when pipeline has trigger request' do
      let!(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline) }

      it 'includes CI_PIPELINE_TRIGGERED and CI_TRIGGER_SHORT_TOKEN' do
        expect(subject.to_hash).to include(
          'CI_PIPELINE_TRIGGERED' => 'true',
          'CI_TRIGGER_SHORT_TOKEN' => trigger_request.trigger_short_token
        )
      end
    end

    context 'when environment tier and url are not passed' do
      let(:job_attr) do
        {
          name: 'rspec:test 2',
          stage: 'test',
          yaml_variables: yaml_variables,
          options: {
            environment: {
              name: 'test/$CI_COMMIT_REF_NAME',
              action: 'prepare'
            }
          },
          **extra_attributes
        }
      end

      it 'returns CI_ENVIRONMENT_TIER and CI_ENVIRONMENT_URL as nil' do
        expect(subject.to_hash).to include('CI_ENVIRONMENT_TIER' => nil)
        expect(subject.to_hash).to include('CI_ENVIRONMENT_URL' => nil)
      end

      context 'when there is an existing environment with the same name' do
        let!(:environment) do
          create(:environment, name: 'test/master', external_url: 'https://hello.test', project: project)
        end

        it 'fetches CI_ENVIRONMENT_TIER and CI_ENVIRONMENT_URL from an old environment' do
          expect(subject.to_hash).to include('CI_ENVIRONMENT_TIER' => 'testing')
          expect(subject.to_hash).to include('CI_ENVIRONMENT_URL' => 'https://hello.test')
        end
      end
    end
  end

  describe '#user_variables' do
    context 'with user' do
      subject { builder.user_variables(user).to_hash }

      let(:expected_variables) do
        {
          'GITLAB_USER_EMAIL' => user.email,
          'GITLAB_USER_ID' => user.id.to_s,
          'GITLAB_USER_LOGIN' => user.username,
          'GITLAB_USER_NAME' => user.name
        }
      end

      it { is_expected.to eq(expected_variables) }
    end

    context 'without user' do
      subject { builder.user_variables(nil).to_hash }

      it { is_expected.to be_empty }
    end
  end

  describe '#kubernetes_variables' do
    let(:service) { double(execute: template) }
    let(:template) { double(to_yaml: 'example-kubeconfig', valid?: template_valid) }
    let(:template_valid) { true }
    let(:environment) { nil }

    subject(:kubernetes_variables) do
      builder.kubernetes_variables(
        environment: environment,
        token: job.token,
        kubernetes_namespace: job.expanded_kubernetes_namespace
      )
    end

    before do
      allow(Ci::GenerateKubeconfigService).to receive(:new).with(job.pipeline, token: job.token, environment: anything).and_return(service)
    end

    it { is_expected.to include(key: 'KUBECONFIG', value: 'example-kubeconfig', public: false, file: true) }

    it 'calls the GenerateKubeconfigService with the correct arguments' do
      expect(Ci::GenerateKubeconfigService).to receive(:new).with(job.pipeline, token: job.token, environment: nil)

      subject
    end

    context 'generated config is invalid' do
      let(:template_valid) { false }

      it { is_expected.not_to include(key: 'KUBECONFIG', value: 'example-kubeconfig', public: false, file: true) }
    end

    context 'when environment is not nil' do
      let(:environment) { 'production' }

      it 'passes the environment when generating the KUBECONFIG' do
        expect(Ci::GenerateKubeconfigService).to receive(:new).with(job.pipeline, token: job.token, environment: 'production')

        subject
      end

      it 'includes #deployment_variables and merges the KUBECONFIG values', :aggregate_failures do
        allow(pipeline.project).to receive(:deployment_variables)
        expect(pipeline.project).to receive(:deployment_variables)
          .with(environment: environment, kubernetes_namespace: job.expanded_kubernetes_namespace)
          .and_return(
            [
              { key: 'KUBECONFIG', value: 'deployment-kubeconfig' },
              { key: 'OTHER', value: 'some value' }
            ])

        expect(template).to receive(:merge_yaml).with('deployment-kubeconfig')
        expect(subject['KUBECONFIG'].value).to eq('example-kubeconfig')
        expect(subject['OTHER'].value).to eq('some value')
      end
    end
  end

  describe '#deployment_variables' do
    let(:environment) { 'production' }
    let(:kubernetes_namespace) { 'namespace' }
    let(:project_deployment_variables) { double }

    subject(:deployment_variables) do
      builder.deployment_variables(environment, kubernetes_namespace)
    end

    before do
      allow(pipeline.project).to receive(:deployment_variables)
        .with(environment: environment, kubernetes_namespace: kubernetes_namespace)
        .and_return(project_deployment_variables)
    end

    it { is_expected.to eq(project_deployment_variables) }

    context 'environment is nil' do
      let(:environment) { nil }

      it { is_expected.to be_empty }
    end
  end

  shared_examples "secret CI variables" do
    let(:protected_variable_item) do
      Gitlab::Ci::Variables::Collection::Item.fabricate(protected_variable)
    end

    let(:unprotected_variable_item) do
      Gitlab::Ci::Variables::Collection::Item.fabricate(unprotected_variable)
    end

    context 'when ref is branch' do
      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: job.ref, project: project)
        end

        it { is_expected.to contain_exactly(protected_variable_item, unprotected_variable_item) }
      end

      context 'when ref is not protected' do
        it { is_expected.to contain_exactly(unprotected_variable_item) }
      end
    end

    context 'when ref is tag' do
      before do
        job.update!(ref: 'v1.1.0', tag: true)
        pipeline.update!(ref: 'v1.1.0', tag: true)
      end

      context 'when ref is protected' do
        before do
          create(:protected_tag, project: project, name: 'v*')
        end

        it { is_expected.to contain_exactly(protected_variable_item, unprotected_variable_item) }
      end

      context 'when ref is not protected' do
        it { is_expected.to contain_exactly(unprotected_variable_item) }
      end
    end

    context 'when ref is merge request' do
      let_it_be(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }
      let_it_be(:pipeline) { merge_request.pipelines_for_merge_request.first }
      let_it_be(:job) { create(:ci_build, ref: merge_request.source_branch, tag: false, pipeline: pipeline) }

      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: merge_request.source_branch, project: project)
        end

        it 'does not return protected variables as it is not supported for merge request pipelines' do
          is_expected.to contain_exactly(unprotected_variable_item)
        end
      end

      context 'when ref is not protected' do
        it { is_expected.to contain_exactly(unprotected_variable_item) }
      end
    end
  end

  describe '#secret_instance_variables' do
    subject { builder.secret_instance_variables }

    let_it_be(:protected_variable) { create(:ci_instance_variable, protected: true) }
    let_it_be(:unprotected_variable) { create(:ci_instance_variable, protected: false) }

    include_examples "secret CI variables"
  end

  describe '#secret_group_variables' do
    subject { builder.secret_group_variables(environment: job.expanded_environment_name) }

    let_it_be(:protected_variable) { create(:ci_group_variable, protected: true, group: group) }
    let_it_be(:unprotected_variable) { create(:ci_group_variable, protected: false, group: group) }

    include_examples "secret CI variables"

    context 'variables memoization' do
      let_it_be(:scoped_variable) { create(:ci_group_variable, group: group, environment_scope: 'scoped') }

      let(:environment) { job.expanded_environment_name }
      let(:scoped_variable_item) { Gitlab::Ci::Variables::Collection::Item.fabricate(scoped_variable) }

      context 'with protected environments' do
        it 'memoizes the result by environment' do
          expect(pipeline.project)
            .to receive(:protected_for?)
            .with(pipeline.jobs_git_ref)
            .once.and_return(true)

          expect_next_instance_of(described_class::Group) do |group_variables_builder|
            expect(group_variables_builder)
              .to receive(:secret_variables)
              .with(environment: 'production', protected_ref: true)
              .once
              .and_call_original
          end

          2.times do
            expect(builder.secret_group_variables(environment: 'production'))
              .to contain_exactly(unprotected_variable_item, protected_variable_item)
          end
        end
      end

      context 'with unprotected environments' do
        it 'memoizes the result by environment' do
          expect(pipeline.project)
            .to receive(:protected_for?)
            .with(pipeline.jobs_git_ref)
            .once.and_return(false)

          expect_next_instance_of(described_class::Group) do |group_variables_builder|
            expect(group_variables_builder)
              .to receive(:secret_variables)
              .with(environment: nil, protected_ref: false)
              .once
              .and_call_original

            expect(group_variables_builder)
              .to receive(:secret_variables)
              .with(environment: 'scoped', protected_ref: false)
              .once
              .and_call_original
          end

          2.times do
            expect(builder.secret_group_variables(environment: nil))
              .to contain_exactly(unprotected_variable_item)

            expect(builder.secret_group_variables(environment: 'scoped'))
              .to contain_exactly(unprotected_variable_item, scoped_variable_item)
          end
        end
      end
    end
  end

  describe '#secret_project_variables' do
    let_it_be(:protected_variable) { create(:ci_variable, protected: true, project: project) }
    let_it_be(:unprotected_variable) { create(:ci_variable, protected: false, project: project) }

    let(:environment) { job.expanded_environment_name }

    subject { builder.secret_project_variables(environment: environment) }

    include_examples "secret CI variables"

    context 'variables memoization' do
      let_it_be(:scoped_variable) { create(:ci_variable, project: project, environment_scope: 'scoped') }

      let(:scoped_variable_item) { Gitlab::Ci::Variables::Collection::Item.fabricate(scoped_variable) }

      context 'with protected environments' do
        it 'memoizes the result by environment' do
          expect(pipeline.project)
            .to receive(:protected_for?)
            .with(pipeline.jobs_git_ref)
            .once.and_return(true)

          expect_next_instance_of(described_class::Project) do |project_variables_builder|
            expect(project_variables_builder)
              .to receive(:secret_variables)
              .with(environment: 'production', protected_ref: true)
              .once
              .and_call_original
          end

          2.times do
            expect(builder.secret_project_variables(environment: 'production'))
              .to contain_exactly(unprotected_variable_item, protected_variable_item)
          end
        end
      end

      context 'with unprotected environments' do
        it 'memoizes the result by environment' do
          expect(pipeline.project)
            .to receive(:protected_for?)
            .with(pipeline.jobs_git_ref)
            .once.and_return(false)

          expect_next_instance_of(described_class::Project) do |project_variables_builder|
            expect(project_variables_builder)
              .to receive(:secret_variables)
              .with(environment: nil, protected_ref: false)
              .once
              .and_call_original

            expect(project_variables_builder)
              .to receive(:secret_variables)
              .with(environment: 'scoped', protected_ref: false)
              .once
              .and_call_original
          end

          2.times do
            expect(builder.secret_project_variables(environment: nil))
              .to contain_exactly(unprotected_variable_item)

            expect(builder.secret_project_variables(environment: 'scoped'))
              .to contain_exactly(unprotected_variable_item, scoped_variable_item)
          end
        end
      end
    end
  end

  describe '#config_variables' do
    subject(:config_variables) { builder.config_variables }

    context 'without repository' do
      let(:project) { create(:project) }
      let(:pipeline) { build(:ci_pipeline, ref: nil, sha: nil, project: project) }

      it { expect(config_variables['CI_COMMIT_SHA']).to be_nil }
    end

    context 'with protected variables' do
      let_it_be(:instance_variable) do
        create(:ci_instance_variable, :protected, key: 'instance_variable')
      end

      let_it_be(:group_variable) do
        create(:ci_group_variable, :protected, group: group, key: 'group_variable')
      end

      let_it_be(:project_variable) do
        create(:ci_variable, :protected, project: project, key: 'project_variable')
      end

      it 'does not include protected variables' do
        expect(config_variables[instance_variable.key]).to be_nil
        expect(config_variables[group_variable.key]).to be_nil
        expect(config_variables[project_variable.key]).to be_nil
      end
    end

    context 'with scoped variables' do
      let_it_be(:scoped_group_variable) do
        create(:ci_group_variable,
          group: group,
          key: 'group_variable',
          value: 'scoped',
          environment_scope: 'scoped')
      end

      let_it_be(:group_variable) do
        create(:ci_group_variable,
          group: group,
          key: 'group_variable',
          value: 'unscoped')
      end

      let_it_be(:scoped_project_variable) do
        create(:ci_variable,
          project: project,
          key: 'project_variable',
          value: 'scoped',
          environment_scope: 'scoped')
      end

      let_it_be(:project_variable) do
        create(:ci_variable,
          project: project,
          key: 'project_variable',
          value: 'unscoped')
      end

      it 'does not include scoped variables' do
        expect(config_variables.to_hash[group_variable.key]).to eq('unscoped')
        expect(config_variables.to_hash[project_variable.key]).to eq('unscoped')
      end
    end

    context 'variables ordering' do
      def var(name, value)
        { key: name, value: value.to_s, public: true, masked: false }
      end

      before do
        pipeline_variables_builder = double(
          ::Gitlab::Ci::Variables::Builder::Pipeline,
          predefined_variables: [var('B', 2), var('C', 2)]
        )

        allow(pipeline.project).to receive(:predefined_variables) { [var('A', 1), var('B', 1)] }
        allow(builder).to receive(:pipeline_variables_builder) { pipeline_variables_builder }
        allow(builder).to receive(:secret_instance_variables) { [var('C', 3), var('D', 3)] }
        allow(builder).to receive(:secret_group_variables) { [var('D', 4), var('E', 4)] }
        allow(builder).to receive(:secret_project_variables) { [var('E', 5), var('F', 5)] }
        allow(pipeline).to receive(:variables) { [var('F', 6), var('G', 6)] }
        allow(pipeline).to receive(:pipeline_schedule) { double(job_variables: [var('G', 7), var('H', 7)]) }
      end

      it 'returns variables in order depending on resource hierarchy' do
        expect(config_variables.to_runner_variables).to eq(
          [var('A', 1), var('B', 1),
           var('B', 2), var('C', 2),
           var('C', 3), var('D', 3),
           var('D', 4), var('E', 4),
           var('E', 5), var('F', 5),
           var('F', 6), var('G', 6),
           var('G', 7), var('H', 7)])
      end

      it 'overrides duplicate keys depending on resource hierarchy' do
        expect(config_variables.to_hash).to match(
          'A' => '1', 'B' => '2',
          'C' => '3', 'D' => '4',
          'E' => '5', 'F' => '6',
          'G' => '7', 'H' => '7')
      end
    end
  end
end
