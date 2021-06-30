# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BaseHooksService do
  include RepoHelpers
  include GitHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { 'refs/tags/v1.1.0' }
  let(:checkout_sha) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }

  let(:test_service) do
    Class.new(described_class) do
      def hook_name
        :push_hooks
      end

      def commits
        []
      end
    end
  end

  subject { test_service.new(project, user, params) }

  let(:params) do
    {
      change: {
        oldrev: oldrev,
        newrev: newrev,
        ref: ref
      }
    }
  end

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
          expect(project).to receive(:execute_integrations)

          subject.execute
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

  describe 'Generating CI variables from push options' do
    let(:pipeline_params) do
      {
        after: newrev,
        before: oldrev,
        checkout_sha: checkout_sha,
        push_options: push_options, # defined in each context
        ref: ref,
        variables_attributes: variables_attributes # defined in each context
      }
    end

    shared_examples 'creates pipeline with params and expected variables' do
      it 'calls the create pipeline service' do
        expect(Ci::CreatePipelineService)
          .to receive(:new)
          .with(project, user, pipeline_params)
          .and_return(double(execute!: true))

        subject.execute
      end
    end

    context 'with empty push options' do
      let(:push_options) { {} }
      let(:variables_attributes) { [] }

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
              "BAR": 1,
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
end
