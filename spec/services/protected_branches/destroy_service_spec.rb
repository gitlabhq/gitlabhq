# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::DestroyService do
  let_it_be_with_reload(:project) { create(:project) }

  let!(:protected_branch) { create(:protected_branch, project: project) }
  let(:user) { project.first_owner }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    it 'destroys a protected branch' do
      service.execute(protected_branch)

      expect(protected_branch).to be_destroyed
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

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
