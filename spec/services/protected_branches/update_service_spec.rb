# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService, feature_category: :compliance_management do
  shared_examples 'execute with entity' do
    let(:params) { { name: new_name } }

    subject(:service) { described_class.new(entity, user, params) }

    describe '#execute' do
      let(:new_name) { 'new protected branch name' }
      let(:result) { service.execute(protected_branch) }

      it 'updates a protected branch' do
        expect(result.reload.name).to eq(params[:name])
      end

      it 'refreshes the cache' do
        expect_next_instance_of(ProtectedBranches::CacheService) do |cache_service|
          expect(cache_service).to receive(:refresh)
        end

        result
      end

      context 'when updating name of a protected branch to one that contains HTML tags' do
        let(:new_name) { 'foo<b>bar<\b>' }
        let(:result) { service.execute(protected_branch) }

        it 'updates a protected branch' do
          expect(result.reload.name).to eq(new_name)
        end
      end

      context 'when a policy restricts rule update' do
        it "prevents update of the protected branch rule" do
          disallow(:update_protected_branch, protected_branch)

          expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'with skip authorization and unauthorized user' do
        let(:user) { create(:user) }
        let(:result) { service.execute(protected_branch, skip_authorization: true) }

        it 'updates a protected branch' do
          expect(result.reload.name).to eq(params[:name])
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
      allow(Ability).to receive(:allowed?).with(user, :update_protected_branch, protected_branch).and_return(true)
    end

    it_behaves_like 'execute with entity'
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
