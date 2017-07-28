require 'spec_helper'

describe ProtectedBranches::CreateService do
  let(:project) { create(:empty_project) }
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
  end
end
