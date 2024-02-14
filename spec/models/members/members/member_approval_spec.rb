# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MemberApproval, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:member_namespace) }
    it { is_expected.to belong_to(:reviewed_by) }
    it { is_expected.to belong_to(:requested_by) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:new_access_level) }
    it { is_expected.to validate_presence_of(:old_access_level) }

    context 'when uniqness is enforced' do
      let!(:member) { create(:project_member) }
      let!(:member_approval) { create(:member_approval, member: member) }

      context 'with same member, namespace, and access level and pending status' do
        let(:message) { 'A pending approval for the same member, namespace, and access level already exists.' }

        it 'disallows on create' do
          duplicate_approval = build(:member_approval, member: member)

          expect(duplicate_approval).not_to be_valid
          expect(duplicate_approval.errors[:base]).to include(message)
        end

        it 'disallows on update' do
          duplicate_approval = create(:member_approval, member: member, status: :approved)
          expect(duplicate_approval).to be_valid

          duplicate_approval.status = ::Members::MemberApproval.statuses[:pending]
          expect(duplicate_approval).not_to be_valid
          expect(duplicate_approval.errors[:base]).to include(message)
        end
      end

      it 'allows duplicate member approvals with different statuses' do
        member_approval.update!(status: ::Members::MemberApproval.statuses[:approved])

        pending_approval = build(:member_approval, member: member)

        expect(pending_approval).to be_valid
      end

      it 'allows duplicate member approvals with different access levels' do
        different_approval = build(:member_approval,
          member: member,
          new_access_level: ::Gitlab::Access::MAINTAINER)

        expect(different_approval).to be_valid
      end
    end
  end
end
