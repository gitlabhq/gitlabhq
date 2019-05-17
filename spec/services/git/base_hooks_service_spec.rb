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
