require 'spec_helper'

describe RunnerEntity do
  let(:runner) { build(:ci_runner) }
  let(:entity) { described_class.represent(runner) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:id, :name, :description)
    end
  end
end
