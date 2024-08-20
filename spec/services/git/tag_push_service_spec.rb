# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::TagPushService, feature_category: :source_code_management do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref }) }

  let(:blankrev) { Gitlab::Git::SHA1_BLANK_SHA }
  let(:oldrev) { blankrev }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:tag)   { 'v1.1.0' }
  let(:ref) { "refs/tags/#{tag}" }

  describe "Push tags" do
    subject do
      service.execute
      service
    end

    it 'flushes general cached data' do
      expect(project.repository).to receive(:before_push_tag)

      subject
    end

    it 'does not flush the tags cache' do
      expect(project.repository).not_to receive(:expire_tags_cache)

      subject
    end
  end

  describe 'Hooks' do
    context 'run on a tag' do
      it 'delegates to Git::TagHooksService' do
        expect_next_instance_of(::Git::TagHooksService) do |hooks_service|
          expect(hooks_service.project).to eq(service.project)
          expect(hooks_service.current_user).to eq(service.current_user)
          expect(hooks_service.params).to eq(service.params)

          expect(hooks_service).to receive(:execute)
        end

        service.execute
      end
    end

    context 'run on a branch' do
      let(:ref) { 'refs/heads/master' }

      it 'does nothing' do
        expect(::Git::BranchHooksService).not_to receive(:new)

        service.execute
      end
    end
  end

  describe 'releases' do
    context 'create tag' do
      let(:oldrev) { blankrev }

      it 'does nothing' do
        expect(Releases::DestroyService).not_to receive(:new)

        service.execute
      end
    end

    context 'update tag' do
      it 'does nothing' do
        expect(Releases::DestroyService).not_to receive(:new)

        service.execute
      end
    end

    context 'delete tag' do
      let(:newrev) { blankrev }

      it 'removes associated releases' do
        expect_next_instance_of(Releases::DestroyService, project, user, tag: tag) do |instance|
          expect(instance).to receive(:execute)
        end

        service.execute
      end
    end
  end

  describe 'artifacts' do
    context 'create tag' do
      let(:oldrev) { blankrev }

      it 'does nothing' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'update tag' do
      it 'does nothing' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'delete tag' do
      let(:newrev) { blankrev }

      it 'unlocks artifacts' do
        expect(::Ci::RefDeleteUnlockArtifactsWorker)
          .to receive(:perform_async).with(project.id, user.id, "refs/tags/#{tag}")

        service.execute
      end
    end
  end
end
