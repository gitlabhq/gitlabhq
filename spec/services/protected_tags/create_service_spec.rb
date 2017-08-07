require 'spec_helper'

describe ProtectedTags::CreateService do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:params) do
    {
      name: 'master',
      create_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }]
    }
  end

  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    it 'creates a new protected tag' do
      expect { service.execute }.to change(ProtectedTag, :count).by(1)
      expect(project.protected_tags.last.create_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
    end
  end
end
