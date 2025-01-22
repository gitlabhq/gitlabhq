# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::BannedUserProjectDeletionWorker, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let(:admin_bot) { Users::Internal.admin_bot }
  let_it_be_with_reload(:user) { create(:user, :banned) }
  let_it_be(:project) { create(:project, creator: user) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { project.id }
    end

    it 'calls Projects::DestroyService' do
      destroy_service = instance_double(Projects::DestroyService)
      expect(Projects::DestroyService).to receive(:new).with(project, admin_bot).and_return(destroy_service)
      expect(destroy_service).to receive(:async_execute)

      worker.perform(project.id)
    end

    it 'does not delete non-existent projects' do
      expect(Projects::DestroyService).not_to receive(:new)

      worker.perform(non_existing_record_id)
    end

    it 'does not delete projects already pending deletion' do
      project.update!(pending_delete: true)
      expect(Projects::DestroyService).not_to receive(:new)

      worker.perform(project.id)
    end

    it 'does not delete projects when the creator is not banned' do
      user.unban!
      expect(Projects::DestroyService).not_to receive(:new)

      worker.perform(non_existing_record_id)
    end
  end
end
