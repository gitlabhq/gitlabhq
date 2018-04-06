require 'rails_helper'

describe DevOpsScore::Metric do
  let(:dev_ops_score) { create(:dev_ops_score_metric) }

  describe '#percentage_score' do
    it 'returns stored percentage score' do
      expect(dev_ops_score.percentage_score('issues')).to eq(13.331)
    end
  end
end
