require 'spec_helper'

describe Tags::DestroyService do
  let(:project) { create(:project, :repository) }
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
