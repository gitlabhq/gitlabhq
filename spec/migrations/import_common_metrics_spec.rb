# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180831164909_import_common_metrics.rb')

describe ImportCommonMetrics, :migration do
  describe '#up' do
    it "imports all prometheus metrics" do
      expect(PrometheusMetric.common).to be_empty

      migrate!

      expect(PrometheusMetric.common).not_to be_empty
    end
  end
end
