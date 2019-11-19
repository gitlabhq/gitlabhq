# frozen_string_literal: true

require 'spec_helper'

describe RemoveExpiredGroupLinksWorker do
  describe '#perform' do
    context 'ProjectGroupLinks' do
      let!(:expired_project_group_link) { create(:project_group_link, expires_at: 1.hour.ago) }
      let!(:project_group_link_expiring_in_future) { create(:project_group_link, expires_at: 10.days.from_now) }
      let!(:non_expiring_project_group_link) { create(:project_group_link, expires_at: nil) }

      it 'removes expired group links' do
        expect { subject.perform }.to change { ProjectGroupLink.count }.by(-1)
        expect(ProjectGroupLink.find_by(id: expired_project_group_link.id)).to be_nil
      end

      it 'leaves group links that expire in the future' do
        subject.perform
        expect(project_group_link_expiring_in_future.reload).to be_present
      end

      it 'leaves group links that do not expire at all' do
        subject.perform
        expect(non_expiring_project_group_link.reload).to be_present
      end
    end

    context 'GroupGroupLinks' do
      let(:mock_destroy_service) { instance_double(Groups::GroupLinks::DestroyService) }

      before do
        allow(Groups::GroupLinks::DestroyService).to(
          receive(:new).and_return(mock_destroy_service))
      end

      context 'expired GroupGroupLink exists' do
        before do
          create(:group_group_link, expires_at: 1.hour.ago)
        end

        it 'calls Groups::GroupLinks::DestroyService' do
          expect(mock_destroy_service).to receive(:execute).once

          subject.perform
        end
      end

      context 'expired GroupGroupLink does not exist' do
        it 'does not call Groups::GroupLinks::DestroyService' do
          expect(mock_destroy_service).not_to receive(:execute)

          subject.perform
        end
      end
    end
  end
end
