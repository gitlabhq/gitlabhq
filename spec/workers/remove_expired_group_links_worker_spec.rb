# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoveExpiredGroupLinksWorker, feature_category: :system_access do
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

      it 'removes project authorization', :sidekiq_inline do
        user = create(:user)

        project = expired_project_group_link.project
        group = expired_project_group_link.group

        group.add_maintainer(user)

        expect { subject.perform }.to(
          change { user.can?(:read_project, project) }.from(true).to(false))
      end
    end

    context 'GroupGroupLinks' do
      context 'expired GroupGroupLink exists' do
        let!(:group_group_link) { create(:group_group_link, expires_at: 1.hour.ago) }

        it 'calls Groups::GroupLinks::DestroyService' do
          mock_destroy_service = instance_double(Groups::GroupLinks::DestroyService)
          allow(Groups::GroupLinks::DestroyService).to(
            receive(:new).and_return(mock_destroy_service))

          expect(mock_destroy_service).to receive(:execute).once

          subject.perform
        end

        context 'with skip_group_share_unlink_auth_refresh feature flag disabled' do
          before do
            stub_feature_flags(skip_group_share_unlink_auth_refresh: false)
          end

          it 'removes project authorization', :sidekiq_inline do
            shared_group = group_group_link.shared_group
            shared_with_group = group_group_link.shared_with_group
            project = create(:project, group: shared_group)

            user = create(:user)
            shared_with_group.add_maintainer(user)

            expect { subject.perform }.to(
              change { user.can?(:read_project, project) }.from(true).to(false))
          end
        end

        context 'with skip_group_share_unlink_auth_refresh feature flag enabled' do
          before do
            stub_feature_flags(skip_group_share_unlink_auth_refresh: true)
          end

          it 'does not remove project authorization', :sidekiq_inline do
            shared_group = group_group_link.shared_group
            shared_with_group = group_group_link.shared_with_group
            project = create(:project, group: shared_group)

            user = create(:user)
            shared_with_group.add_maintainer(user)

            subject.perform

            expect(user.can?(:read_project, project)).to be_truthy
          end
        end
      end

      context 'expired GroupGroupLink does not exist' do
        it 'does not call Groups::GroupLinks::DestroyService' do
          mock_destroy_service = instance_double(Groups::GroupLinks::DestroyService)
          allow(Groups::GroupLinks::DestroyService).to(
            receive(:new).and_return(mock_destroy_service))

          expect(mock_destroy_service).not_to receive(:execute)

          subject.perform
        end
      end
    end
  end
end
