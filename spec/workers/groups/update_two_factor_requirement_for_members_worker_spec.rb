# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateTwoFactorRequirementForMembersWorker, feature_category: :system_access do
  let_it_be_with_reload(:group) { create(:group) }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes Authn::Groups::UpdateTwoFactorRequirementService for the group' do
      expect_next_instance_of(Authn::Groups::UpdateTwoFactorRequirementService, group: group) do |service|
        expect(service).to receive(:execute)
      end

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
