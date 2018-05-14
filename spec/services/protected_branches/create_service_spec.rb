require 'spec_helper'

describe ProtectedBranches::CreateService do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:params) do
    {
      name: 'master',
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }]
    }
  end

  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    it 'creates a new protected branch' do
      expect { service.execute }.to change(ProtectedBranch, :count).by(1)
      expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
      expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
    end

    context 'when user does not have permission' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
      end

      it 'creates a new protected branch if we skip authorization step' do
        expect { service.execute(skip_authorization: true) }.to change(ProtectedBranch, :count).by(1)
      end

      it 'raises Gitlab::Access:AccessDeniedError' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when a policy restricts rule creation' do
      before do
        policy = instance_double(ProtectedBranchPolicy, can?: false)
        expect(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents creation of the protected branch rule" do
        expect do
          service.execute
        end.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
