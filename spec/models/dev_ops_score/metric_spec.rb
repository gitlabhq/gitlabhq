# frozen_string_literal: true

require 'spec_helper'

describe DevOpsScore::Metric do
  let(:conv_dev_index) { create(:dev_ops_score_metric) }

  describe '#percentage_score' do
    it 'returns stored percentage score' do
      expect(conv_dev_index.percentage_score('issues')).to eq(13.331)
    end
  end
end
