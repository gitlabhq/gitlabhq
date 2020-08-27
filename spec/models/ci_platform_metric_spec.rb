# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CiPlatformMetric do
  subject { build(:ci_platform_metric) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_presence_of(:platform_target) }
    it { is_expected.to validate_length_of(:platform_target).is_at_most(255) }
  end

  describe '.update!' do
    def platform_target_counts_by_day
      report = Hash.new { |hash, key| hash[key] = {} }
      CiPlatformMetric.all.each do |metric|
        date = metric.recorded_at.to_date
        report[date][metric.platform_target] = metric.count
      end
      report
    end

    context "when there is already existing metrics data" do
      let!(:metric_1) { create(:ci_platform_metric) }
      let!(:metric_2) { create(:ci_platform_metric) }

      it "does not erase any existing data" do
        CiPlatformMetric.update!

        expect(CiPlatformMetric.all.to_a).to contain_exactly(metric_1, metric_2)
      end
    end

    context "when there are multiple platform target variables" do
      let(:today) { Time.zone.local(1982, 4, 24) }
      let(:tomorrow) { today + 1.day }

      it "updates platform target counts for that day" do
        Timecop.freeze(today) do
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "aws")
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "aws")
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "fargate")
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "fargate")
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "fargate")
          CiPlatformMetric.update!
        end
        Timecop.freeze(tomorrow) do
          create(:ci_variable, key: described_class::CI_VARIABLE_KEY, value: "fargate")
          CiPlatformMetric.update!
        end

        expect(platform_target_counts_by_day).to eq({
          today.to_date => { "aws" => 2, "fargate" => 3 },
          tomorrow.to_date => { "aws" => 2, "fargate" => 4 }
        })
      end
    end

    context "when there are no platform target variables" do
      it "does not generate any new platform metrics" do
        create(:ci_variable, key: "KEY_WHATEVER", value: "aws")
        CiPlatformMetric.update!

        expect(platform_target_counts_by_day).to eq({})
      end
    end
  end
end
