require 'spec_helper'

describe ProtectedTags::DestroyService do
  let(:protected_tag) { create(:protected_tag) }
  let(:project) { protected_tag.project }
  let(:user) { project.owner }

  describe '#execute' do
    subject(:service) { described_class.new(project, user) }

    it 'destroy a protected tag' do
      service.execute(protected_tag)

      expect(protected_tag).to be_destroyed
    end
  end
end
