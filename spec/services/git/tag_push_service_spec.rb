# frozen_string_literal: true

require 'spec_helper'

describe Git::TagPushService do
  include RepoHelpers
  include GitHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref) }

  let(:oldrev) { Gitlab::Git::BLANK_SHA }
  let(:newrev) { "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" } # gitlab-test: git rev-parse refs/tags/v1.1.0
  let(:ref) { 'refs/tags/v1.1.0' }

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
end
