# frozen_string_literal: true

require 'spec_helper'

describe Git::BaseHooksService do
  include RepoHelpers
  include GitHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { 'refs/tags/v1.1.0' }

  describe '#execute_project_hooks' do
    class TestService < described_class
      def hook_name
        :push_hooks
      end

      def commits
        []
      end
    end

    let(:project) { create(:project, :repository) }

    let(:params) do
      {
        change: {
          oldrev: oldrev,
          newrev: newrev,
          ref: ref
        }
      }
    end

    subject { TestService.new(project, user, params) }

    context '#execute_hooks' do
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

    context '#execute_services' do
      before do
        expect(project).to receive(:has_active_services?).and_return(active)
      end

      context 'active services' do
        let(:active) { true }

        it 'executes the services' do
          expect(subject).to receive(:push_data).at_least(:once).and_call_original
          expect(project).to receive(:execute_services)

          subject.execute
        end
      end

      context 'inactive services' do
        let(:active) { false }

        it 'does not execute the services' do
          expect(subject).not_to receive(:push_data)
          expect(project).not_to receive(:execute_services)

          subject.execute
        end
      end
    end

    context 'execute_project_hooks param set to false' do
      before do
        params[:execute_project_hooks] = false

        allow(project).to receive(:has_active_hooks?).and_return(true)
        allow(project).to receive(:has_active_services?).and_return(true)
      end

      it 'does not execute hooks and services' do
        expect(project).not_to receive(:execute_hooks)
        expect(project).not_to receive(:execute_services)

        subject.execute
      end
    end
  end
end
