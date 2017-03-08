require 'spec_helper'

describe Boards::UpdateService, services: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let!(:board)  { create(:board, project: project, name: 'Backend') }

    it "updates board's name" do
      service = described_class.new(project, double, name: 'Engineering')

      service.execute(board)

      expect(board).to have_attributes(name: 'Engineering')
    end

    it 'returns true with valid params' do
      service = described_class.new(project, double, name: 'Engineering')

      expect(service.execute(board)).to eq true
    end

    it 'returns false with invalid params' do
      service = described_class.new(project, double, name: nil)

      expect(service.execute(board)).to eq false
    end
  end
end
