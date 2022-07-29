# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService do
  let(:protected_branch) { create(:protected_branch) }
  let(:project) { protected_branch.project }
  let(:user) { project.first_owner }
  let(:params) { { name: new_name } }

  describe '#execute' do
    let(:new_name) { 'new protected branch name' }
    let(:result) { service.execute(protected_branch) }

    subject(:service) { described_class.new(project, user, params) }

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

      subject(:service) { described_class.new(project, user, params) }

      it 'updates a protected branch' do
        expect(result.reload.name).to eq(new_name)
      end
    end

    context 'without admin_project permissions' do
      let(:user) { create(:user) }

      it "raises error" do
        expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when a policy restricts rule creation' do
      before do
        policy = instance_double(ProtectedBranchPolicy, allowed?: false)
        expect(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents creation of the protected branch rule" do
        expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
