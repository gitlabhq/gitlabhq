# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService do
  let(:protected_branch) { create(:protected_branch) }
  let(:project) { protected_branch.project }
  let(:user) { project.owner }
  let(:params) { { name: 'new protected branch name' } }

  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    it 'updates a protected branch' do
      result = service.execute(protected_branch)

      expect(result.reload.name).to eq(params[:name])
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
