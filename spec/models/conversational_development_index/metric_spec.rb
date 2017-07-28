require 'spec_helper'

describe ConversationalDevelopmentIndex::Metric do
  let(:conv_dev_index) { build(:conversational_development_index_metric) }

  describe '#instance_score' do
    it 'returns the instance score' do
      expect(conv_dev_index.instance_score('issues')).to eq(1.234)
    end
  end

  describe '#leader_score' do
    it 'returns the instance score' do
      expect(conv_dev_index.leader_score('issues')).to eq(9.256)
    end
  end

  describe '#percentage_score' do
    it 'returns the stored percentage score' do
      expect(conv_dev_index.percentage_score('issues')).to eq(13.33)
    end

    it 'returns the calculated percentage score for not scored metrics' do
      expect(conv_dev_index.percentage_score('notes')).to be_within(95.0).of(100.0)
    end
  end
end
