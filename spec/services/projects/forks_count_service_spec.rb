require 'spec_helper'

describe Projects::ForksCountService do
  describe '#count' do
    it 'returns the number of forks' do
      project = build(:project, id: 42)
      service = described_class.new(project)

      allow(service).to receive(:uncached_count).and_return(1)

      expect(service.count).to eq(1)
    end
  end
end
