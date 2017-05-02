require 'spec_helper'

describe Ci::Group, models: true do
  subject { described_class.new('test', name: 'rspec', statuses: []) }

  describe 'expectations' do
    it { is_expected.to include_module(StaticModel) }

    it { is_expected.to respond_to(:stage) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:statuses) }
  end

  describe '#size' do
    it 'returns the size of the statusses array' do
      expect(subject.size).to eq(0)
    end
  end
end
