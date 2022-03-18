# frozen_string_literal: true

RSpec.shared_examples 'a usage counter' do
  describe '.increment' do
    let(:project_id) { 12 }

    it 'intializes and increments the counter for the project by 1' do
      expect do
        described_class.increment(project_id)
      end.to change { described_class.usage_totals[project_id] }.from(nil).to(1)
    end
  end

  describe '.usage_totals' do
    let(:usage_totals) { described_class.usage_totals }

    context 'when the feature has not been used' do
      it 'returns the total counts and counts per project' do
        expect(usage_totals.keys).to eq([:total])
        expect(usage_totals[:total]).to eq(0)
      end
    end

    context 'when the feature has been used in multiple projects' do
      let(:project1_id) { 12 }
      let(:project2_id) { 16 }

      before do
        described_class.increment(project1_id)
        described_class.increment(project2_id)
      end

      it 'returns the total counts and counts per project' do
        expect(usage_totals[project1_id]).to eq(1)
        expect(usage_totals[project2_id]).to eq(1)
        expect(usage_totals[:total]).to eq(2)
      end
    end
  end
end
