require 'rails_helper'

describe ConversationalDevelopmentIndex::Metric do
  let(:conv_dev_index) { create(:conversational_development_index_metric) }

  describe '#percentage_score' do
    it 'returns stored percentage score' do
      expect(conv_dev_index.percentage_score('issues')).to eq(13.331)
    end
  end
end
