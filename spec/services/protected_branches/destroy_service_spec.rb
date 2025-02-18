# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::DestroyService, feature_category: :compliance_management do
  shared_examples 'execute with entity' do
    subject(:service) { described_class.new(entity, user) }

    describe '#execute' do
      it 'destroys a protected branch' do
        service.execute(protected_branch)

        expect(protected_branch).to be_destroyed
      end

      it 'publishes ProtectedBranchDestroyedEvent event' do
        expect { service.execute(protected_branch) }.to publish_event(Repositories::ProtectedBranchDestroyedEvent)
          .with(parent_id: entity.id, parent_type: entity.is_a?(Project) ? 'project' : 'group')
      end

      it 'refreshes the cache' do
        expect_next_instance_of(ProtectedBranches::CacheService) do |cache_service|
          expect(cache_service).to receive(:refresh)
        end

        service.execute(protected_branch)
      end

      context 'when a policy restricts rule deletion' do
        it "prevents deletion of the protected branch rule" do
          disallow(:destroy_protected_branch, protected_branch)

          expect do
            service.execute(protected_branch)
          end.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  context 'with entity project' do
    let_it_be_with_reload(:entity) { create(:project) }
    let!(:protected_branch) { create(:protected_branch, project: entity) }
    let(:user) { entity.first_owner }

    it_behaves_like 'execute with entity'
  end

  context 'with entity group' do
    let_it_be_with_reload(:entity) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }
    let!(:protected_branch) { create(:protected_branch, group: entity, project: nil) }

    before do
      allow(Ability).to receive(:allowed?).with(user, :destroy_protected_branch, protected_branch).and_return(true)
    end

    it_behaves_like 'execute with entity'
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
