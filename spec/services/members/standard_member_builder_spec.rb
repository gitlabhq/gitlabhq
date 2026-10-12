# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::StandardMemberBuilder, feature_category: :groups_and_projects do
  let_it_be(:source) { create(:group) }
  let_it_be(:existing_member) { create(:group_member) }

  let(:existing_members) { { existing_member.user.id => existing_member } }

  describe '#execute' do
    it 'returns member from existing members hash' do
      expect(described_class.new(source, existing_member.user, existing_members).execute).to eq existing_member
    end

    it 'builds a new member' do
      user = create(:user)

      member = described_class.new(source, user, existing_members).execute

      expect(member).to be_new_record
      expect(member.user).to eq user
    end

    it 'does not destroy a pending invite for the same email before the member is saved' do
      user = create(:user)
      create(:group_member, :invited, source: source, invite_email: user.email)

      expect { described_class.new(source, user, existing_members).execute }
        .not_to change { source.members_and_requesters.invite.count }
    end
  end

  describe '#after_commit' do
    let_it_be(:user) { create(:user) }
    let!(:pending_invite) { create(:group_member, :invited, source: source, invite_email: user.email) }

    context 'when the member was newly persisted' do
      subject(:after_commit) { described_class.new(source, user, existing_members).after_commit(member) }

      let(:member) do
        source.members_and_requesters.create!(user_id: user.id, access_level: Gitlab::Access::DEVELOPER)
      end

      it 'destroys the pending invite for the same email' do
        expect { after_commit }.to change { source.members_and_requesters.invite.count }.by(-1)
      end

      it 'does not destroy a pending invite for a different email' do
        create(:group_member, :invited, source: source, invite_email: 'someone-else@example.com')

        expect { after_commit }
          .not_to change { source.members_and_requesters.invite.where(invite_email: 'someone-else@example.com').count }
      end

      context 'when the user has no email' do
        before do
          allow(user).to receive(:email).and_return('')
        end

        it 'does not destroy any pending invite' do
          expect { after_commit }.not_to change { source.members_and_requesters.invite.count }
        end
      end

      context 'when destroying the pending invite fails' do
        before do
          allow_next_found_instance_of(Member) do |invite|
            allow(invite).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
          end
        end

        it 'tracks the error instead of failing the call' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            .with(instance_of(ActiveRecord::RecordNotDestroyed), member_id: pending_invite.id, source_id: source.id)

          expect { after_commit }.not_to raise_error
        end
      end
    end

    context 'when the member save failed (e.g. a uniqueness race with a concurrent sync)' do
      it 'does not destroy the pending invite', :aggregate_failures do
        # Simulate the race this guards against: another process already created a member
        # for this user+source, so this build's own save fails the uniqueness validation.
        create(:group_member, source: source, user: user)
        member = source.members_and_requesters.build(user_id: user.id)

        expect(member.save).to be false
        expect(member.previously_new_record?).to be false

        expect { described_class.new(source, user, existing_members).after_commit(member) }
          .not_to change { source.members_and_requesters.invite.count }
      end
    end

    context 'when the member already existed (not newly created)' do
      it 'does not destroy any pending invite for the same email' do
        expect { described_class.new(source, existing_member.user, existing_members).after_commit(existing_member) }
          .not_to change { source.members_and_requesters.invite.count }
      end
    end
  end
end
