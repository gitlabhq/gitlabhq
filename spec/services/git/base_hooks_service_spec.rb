# frozen_string_literal: true

require 'spec_helper'

describe Git::BaseHooksService do
  include RepoHelpers
  include GitHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

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

    subject { TestService.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

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
  end

  describe 'with remote mirrors' do
    class TestService < described_class
      def commits
        []
      end
    end

    let(:project) { create(:project, :repository, :remote_mirror) }

    subject { TestService.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

    before do
      expect(subject).to receive(:execute_project_hooks)
    end

    context 'when remote mirror feature is enabled' do
      it 'fails stuck remote mirrors' do
        allow(project).to receive(:update_remote_mirrors).and_return(project.remote_mirrors)
        expect(project).to receive(:mark_stuck_remote_mirrors_as_failed!)

        subject.execute
      end

      it 'updates remote mirrors' do
        expect(project).to receive(:update_remote_mirrors)

        subject.execute
      end
    end

    context 'when remote mirror feature is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'with remote mirrors global setting overridden' do
        before do
          project.remote_mirror_available_overridden = true
        end

        it 'fails stuck remote mirrors' do
          allow(project).to receive(:update_remote_mirrors).and_return(project.remote_mirrors)
          expect(project).to receive(:mark_stuck_remote_mirrors_as_failed!)

          subject.execute
        end

        it 'updates remote mirrors' do
          expect(project).to receive(:update_remote_mirrors)

          subject.execute
        end
      end

      context 'without remote mirrors global setting overridden' do
        before do
          project.remote_mirror_available_overridden = false
        end

        it 'does not fails stuck remote mirrors' do
          expect(project).not_to receive(:mark_stuck_remote_mirrors_as_failed!)

          subject.execute
        end

        it 'does not updates remote mirrors' do
          expect(project).not_to receive(:update_remote_mirrors)

          subject.execute
        end
      end
    end
  end
end
