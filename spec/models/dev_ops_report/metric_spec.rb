# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DevOpsReport::Metric do
  let(:conv_dev_index) { create(:dev_ops_report_metric) }

  describe 'validations' do
    DevOpsReport::Metric::METRICS.each do |metric_name|
      it { is_expected.to validate_presence_of(metric_name) }
      it { is_expected.to validate_numericality_of(metric_name).is_greater_than_or_equal_to(0) }
    end
  end

  describe '#percentage_score' do
    it 'returns stored percentage score' do
      expect(conv_dev_index.percentage_score('issues')).to eq(13.331)
    end
  end
end
