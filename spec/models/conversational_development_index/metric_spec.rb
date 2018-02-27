require 'rails_helper'

describe DevOpsScore::Metric do
  let(:devops_score) { create(:devops_score_metric) }

  describe '#percentage_score' do
    it 'returns stored percentage score' do
      expect(devops_score.percentage_score('issues')).to eq(13.331)
    end
  end
end
