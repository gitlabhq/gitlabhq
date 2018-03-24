require 'spec_helper'

describe ProtectedBranches::DestroyService do
  let(:protected_branch) { create(:protected_branch) }
  let(:project) { protected_branch.project }
  let(:user) { project.owner }

  describe '#execute' do
    subject(:service) { described_class.new(project, user) }

    it 'destroys a protected branch' do
      service.execute(protected_branch)

      expect(protected_branch).to be_destroyed
    end
  end
end
