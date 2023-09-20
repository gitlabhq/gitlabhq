# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::ApiService, feature_category: :compliance_management do
  shared_examples 'execute with entity' do
    it 'creates a protected branch with prefilled defaults' do
      expect(::ProtectedBranches::CreateService).to receive(:new).with(
        entity,
        user,
        hash_including(
          push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
        )
      ).and_call_original

      expect(described_class.new(entity, user, { name: 'new name' }).create).to be_valid
    end

    it 'updates a protected branch without prefilled defaults' do
      expect(::ProtectedBranches::UpdateService).to receive(:new).with(
        entity,
        user,
        hash_including(
          push_access_levels_attributes: [],
          merge_access_levels_attributes: []
        )
      ).and_call_original

      expect do
        expect(described_class.new(entity, user, { name: 'new name' }).update(protected_branch)).to be_valid
      end.not_to change { protected_branch.reload.allow_force_push }
    end
  end

  context 'with entity project' do
    let_it_be_with_reload(:entity) { create(:project) }
    let_it_be_with_reload(:protected_branch) { create(:protected_branch, project: entity, allow_force_push: true) }
    let(:user) { entity.first_owner }

    it_behaves_like 'execute with entity'
  end

  context 'with entity group' do
    let_it_be_with_reload(:entity) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be_with_reload(:protected_branch) do
      create(:protected_branch, group: entity, project: nil, allow_force_push: true)
    end

    before do
      allow(Ability).to receive(:allowed?).with(user, :update_protected_branch, protected_branch).and_return(true)
      allow(Ability)
        .to receive(:allowed?)
        .with(user, :create_protected_branch, instance_of(ProtectedBranch))
        .and_return(true)
    end

    it_behaves_like 'execute with entity'
  end
end
