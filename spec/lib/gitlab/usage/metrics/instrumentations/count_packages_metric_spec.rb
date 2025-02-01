# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountPackagesMetric, feature_category: :service_ping do
  before_all do
    create(:generic_package, created_at: 2.months.ago)
    create(:generic_package, created_at: 21.days.ago)
    create(:generic_package, created_at: 7.days.ago)
  end

  context "with all time frame" do
    let(:expected_value) { 3 }
    let(:expected_query) do
      'SELECT COUNT("packages_packages"."id") FROM "packages_packages"'
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
  end

  context "with 28d time frame" do
    let(:expected_value) { 2 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      'SELECT COUNT("packages_packages"."id") FROM "packages_packages" ' \
        'WHERE "packages_packages"."created_at" ' \
        "BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' }
  end
end
