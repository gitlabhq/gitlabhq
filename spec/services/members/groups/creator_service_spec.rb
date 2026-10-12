# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::CreatorService, feature_category: :groups_and_projects do
  let_it_be_with_reload(:source) { create(:group, :public) }
  let_it_be_with_reload(:source2) { create(:group, :public) }
  let_it_be(:user) { create(:user) }

  describe '.access_levels' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end

  it_behaves_like 'owner management'

  describe '.add_members' do
    it_behaves_like 'bulk member creation' do
      let_it_be(:source_type) { Group }
      let_it_be(:member_type) { GroupMember }
    end
  end

  describe '.add_member' do
    it_behaves_like 'member creation' do
      let_it_be(:member_type) { GroupMember }
    end

    context 'when there is a pending invite for the same email' do
      let_it_be_with_reload(:pending_invite) do
        create(:group_member, :invited, source: source, invite_email: user.email)
      end

      it 'removes the orphaned pending invite end-to-end through run_after_commit_or_now' do
        described_class.add_member(source, user, :developer)

        expect { pending_invite.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'when the member save fails validation' do
        let_it_be(:subgroup) { create(:group, parent: source) }
        let_it_be(:subgroup_pending_invite) do
          create(:group_member, :invited, source: subgroup, invite_email: user.email)
        end

        before_all do
          source.add_maintainer(user) # subgroup :developer is below this, failing the real access_level validation
        end

        it 'does not destroy the pending invite' do
          member = described_class.add_member(subgroup, user, :developer)

          expect(member).not_to be_persisted
          expect(subgroup.members_and_requesters.invite.count).to eq(1)
        end
      end
    end

    it_behaves_like 'member creation with organization isolation' do
      let_it_be(:source_type) { Group }
    end

    context 'authorized projects update' do
      it 'schedules a single project authorization update job when called multiple times' do
        # this is inline with the overridden behaviour in stubbed_member.rb
        worker_instance = AuthorizedProjectsWorker.new
        expect(AuthorizedProjectsWorker).to receive(:new).once.and_return(worker_instance)
        expect(worker_instance).to receive(:perform).with(user.id)

        1.upto(3) do
          described_class.add_member(source, user, :maintainer)
        end
      end

      context 'with skip_authorized_projects_refresh: true' do
        it 'does not schedule a project authorization update job' do
          expect(AuthorizedProjectsWorker).not_to receive(:new)

          described_class.add_member(source, user, :maintainer, skip_authorized_projects_refresh: true)
        end
      end
    end

    context 'with immediately_sync_authorizations: true' do
      it 'does nothing for groups' do
        expect(ProjectAuthorization).not_to receive(:find_or_create_authorization_for)

        described_class.add_member(source, user, :maintainer, immediately_sync_authorizations: true)
      end
    end

    context 'service account membership eligibility' do
      let_it_be(:owner) { create(:user, owner_of: source) }

      context 'when the service account is not eligible for membership' do
        let(:ineligible_sa) do
          subgroup = create(:group, parent: source)
          create(:user, :service_account, provisioned_by_group: subgroup)
        end

        it 'does not create the member when inviting up the hierarchy' do
          member = described_class.add_member(source, ineligible_sa, :developer, current_user: owner)

          expect(member).not_to be_persisted
          expect(member.errors.full_messages).to include(/not authorized to create member/)
        end
      end

      context 'when the service account is eligible for membership' do
        let(:eligible_sa) { create(:user, :service_account, provisioned_by_group: source) }

        it 'creates the member' do
          member = described_class.add_member(source, eligible_sa, :developer, current_user: owner)

          expect(member).to be_persisted
        end
      end
    end
  end
end
