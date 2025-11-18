# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BaseHooksService, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { 'refs/tags/v1.1.0' }
  let(:checkout_sha) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }

  let(:test_service) do
    Class.new(described_class) do
      def hook_name
        :push_hooks
      end

      def limited_commits
        []
      end

      def commits_count
        0
      end
    end
  end

  let(:params) do
    {
      change: {
        oldrev: oldrev,
        newrev: newrev,
        ref: ref
      }
    }
  end

  subject { test_service.new(project, user, params) }

  describe 'push event' do
    it 'creates push event' do
      expect_next_instance_of(EventCreateService) do |service|
        expect(service).to receive(:push)
      end

      subject.execute
    end

    context 'create_push_event is set to false' do
      before do
        params[:create_push_event] = false
      end

      it 'does not create push event' do
        expect(EventCreateService).not_to receive(:new)

        subject.execute
      end
    end
  end

  describe 'project hooks and integrations' do
    context 'hooks' do
      before do
        expect(project).to receive(:has_active_hooks?).and_return(active)
      end

      context 'active hooks' do
        let(:active) { true }

        it 'executes the hooks' do
          expect(subject).to receive(:push_data).at_least(:once).and_call_original
          expect(project).to receive(:execute_hooks)

          subject.execute
        end
      end

      context 'inactive hooks' do
        let(:active) { false }

        it 'does not execute the hooks' do
          expect(subject).not_to receive(:push_data)
          expect(project).not_to receive(:execute_hooks)

          subject.execute
        end
      end
    end

    context 'with integrations' do
      before do
        expect(project).to receive(:has_active_integrations?).and_return(active)
      end

      context 'with active integrations' do
        let(:active) { true }

        it 'executes the services' do
          expect(subject).to receive(:push_data).at_least(:once).and_call_original
          expect(project).to receive(:execute_integrations).with(kind_of(Hash), subject.hook_name, skip_ci: false)

          subject.execute
        end

        context 'with integrations.skip_ci push option' do
          before do
            params[:push_options] = {
              integrations: { skip_ci: true }
            }
          end

          it 'executes the services' do
            expect(subject).to receive(:push_data).at_least(:once).and_call_original
            expect(project).to receive(:execute_integrations).with(kind_of(Hash), subject.hook_name, skip_ci: true)

            subject.execute
          end
        end
      end

      context 'with inactive integrations' do
        let(:active) { false }

        it 'does not execute the services' do
          expect(subject).not_to receive(:push_data)
          expect(project).not_to receive(:execute_integrations)

          subject.execute
        end
      end
    end

    context 'when execute_project_hooks param is set to false' do
      before do
        params[:execute_project_hooks] = false

        allow(project).to receive(:has_active_hooks?).and_return(true)
        allow(project).to receive(:has_active_integrations?).and_return(true)
      end

      it 'does not execute hooks and integrations' do
        expect(project).not_to receive(:execute_hooks)
        expect(project).not_to receive(:execute_integrations)

        subject.execute
      end
    end
  end

  describe 'Pipeline push options' do
    context 'when push options contain inputs' do
      let(:pipeline_params) do
        {
          after: newrev,
          before: oldrev,
          checkout_sha: checkout_sha,
          push_options: an_instance_of(Ci::PipelineCreation::PushOptions),
          gitaly_context: {},
          ref: ref,
          variables_attributes: []
        }
      end

      let(:push_options) do
        {
          ci: {
            input: {
              'deploy_strategy=blue-green': 1,
              'job_stage=test': 1,
              'allow_failure=true': 1,
              'parallel_jobs=3': 1,
              'test_script=["echo 1", "echo 2"]': 1,
              'test_rules=[{"if": "$CI_MERGE_REQUEST_ID"}, {"if": "$CI_COMMIT_BRANCH == $CI_COMMIT_BRANCH"}]': 1
            }
          }
        }
      end

      before_all do
        project.add_maintainer(user)
      end

      before do
        stub_ci_pipeline_yaml_file(
          File.read(Rails.root.join('spec/lib/gitlab/ci/config/yaml/fixtures/complex-included-ci.yml'))
        )

        params[:push_options] = push_options
      end

      it 'triggers an async pipeline creation', :sidekiq_inline do
        allow(Ci::CreatePipelineService).to receive(:new).and_call_original
        expect(Ci::CreatePipelineService)
          .to receive(:new)
          .with(project, user, pipeline_params.merge(push_options: push_options.deep_stringify_keys))
          .and_call_original

        expect { subject.execute }.to change { Ci::Pipeline.count }.by(1)

        pipeline = Ci::Pipeline.last

        my_job_test = pipeline.builds.find { |build| build.name == 'my-job-test' }
        expect(my_job_test.allow_failure).to be(true)

        expect(pipeline.builds.count { |build| build.name.starts_with?('my-job-build') }).to eq(3)

        my_job_test2 = pipeline.builds.find { |build| build.name == 'my-job-test-2' }
        expect(my_job_test2.options[:script]).to eq(["echo 1", "echo 2"])

        my_job_deploy = pipeline.builds.find { |build| build.name == 'my-job-deploy' }
        expect(my_job_deploy.options[:script]).to eq(['echo "Deploying to staging using blue-green strategy"'])
      end
    end
  end

  describe 'Generating CI variables from push options' do
    let(:pipeline_params) do
      {
        after: newrev,
        before: oldrev,
        checkout_sha: checkout_sha,
        push_options: an_instance_of(Ci::PipelineCreation::PushOptions), # defined in each context
        gitaly_context: {},
        ref: ref,
        variables_attributes: variables_attributes # defined in each context
      }
    end

    shared_examples 'creates pipeline with params and expected variables' do
      let(:pipeline_service) { double(execute_async: service_response) }
      let(:service_response) { double(error?: false) }

      it 'triggers an async pipeline creation' do
        expect(Ci::CreatePipelineService)
          .to receive(:new)
                .with(project, user, pipeline_params.merge(push_options: push_options&.deep_stringify_keys))
                .and_return(pipeline_service)
        expect(subject).not_to receive(:log_pipeline_errors)

        subject.execute
      end
    end

    context 'without providing push options' do
      let(:push_options) { nil }
      let(:variables_attributes) { [] }

      it_behaves_like 'creates pipeline with params and expected variables'
    end

    context 'with empty push options' do
      let(:push_options) { {} }
      let(:variables_attributes) { [] }

      before do
        params[:push_options] = push_options
      end

      it_behaves_like 'creates pipeline with params and expected variables'
    end

    context 'with push options not specifying variables' do
      let(:push_options) do
        {
          mr: {
            create: true
          }
        }
      end

      let(:variables_attributes) { [] }

      before do
        params[:push_options] = push_options
      end

      it_behaves_like 'creates pipeline with params and expected variables'
    end

    context 'with push options specifying variables' do
      let(:push_options) do
        {
          ci: {
            variable: {
              "FOO=123": 1,
              "BAR=456": 1,
              "MNO=890=ABC": 1
            }
          }
        }
      end

      let(:variables_attributes) do
        [
          { "key" => "FOO", "variable_type" => "env_var", "secret_value" => "123" },
          { "key" => "BAR", "variable_type" => "env_var", "secret_value" => "456" },
          { "key" => "MNO", "variable_type" => "env_var", "secret_value" => "890=ABC" }
        ]
      end

      before do
        params[:push_options] = push_options
      end

      it_behaves_like 'creates pipeline with params and expected variables'
    end

    context 'with push options not specifying variables in correct format' do
      let(:push_options) do
        {
          ci: {
            variable: {
              "FOO=123": 1,
              BAR: 1,
              "=MNO": 1
            }
          }
        }
      end

      let(:variables_attributes) do
        [
          { "key" => "FOO", "variable_type" => "env_var", "secret_value" => "123" }
        ]
      end

      before do
        params[:push_options] = push_options
      end

      it_behaves_like 'creates pipeline with params and expected variables'
    end
  end

  describe 'notifying KAS' do
    let(:kas_enabled) { true }

    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(kas_enabled)
    end

    it 'enqueues the notification worker' do
      expect(Clusters::Agents::NotifyGitPushWorker).to receive(:perform_async).with(project.id).once

      subject.execute
    end

    context 'when KAS is disabled' do
      let(:kas_enabled) { false }

      it do
        expect(Clusters::Agents::NotifyGitPushWorker).not_to receive(:perform_async)

        subject.execute
      end
    end
  end
end
