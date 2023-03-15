# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateTwoFactorRequirementForMembersWorker, feature_category: :system_access do
  let_it_be(:group) { create(:group) }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'calls #update_two_factor_requirement_for_members' do
      allow(Group).to receive(:find_by_id).with(group.id).and_return(group)
      expect(group).to receive(:update_two_factor_requirement_for_members)

      worker.perform(group.id)
    end

    context 'when group not found' do
      it 'returns nil' do
        expect(worker.perform(non_existing_record_id)).to be_nil
      end
    end

    include_examples 'an idempotent worker' do
      let(:subject) { described_class.new.perform(group.id) }

      it 'requires 2fa for group members correctly' do
        group.update!(require_two_factor_authentication: true)
        user = create(:user, require_two_factor_authentication_from_group: false)
        group.add_member(user, GroupMember::OWNER)

        # Using subject inside this block will process the job multiple times
        subject

        expect(user.reload.require_two_factor_authentication_from_group).to be true
      end
    end
  end
end
