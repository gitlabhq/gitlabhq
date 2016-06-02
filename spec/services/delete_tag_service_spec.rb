require 'spec_helper'

describe DeleteTagService, services: true do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    it 'removes the tag' do
      expect(repository).to receive(:before_remove_tag)
      expect(service).to receive(:success)

      service.execute('v1.1.0')
    end
  end
end
