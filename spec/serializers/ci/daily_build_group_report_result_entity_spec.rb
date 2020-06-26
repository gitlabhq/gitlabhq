# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultEntity do
  let(:report_result) { double(date: '2020-05-20', group_name: 'rspec', data: { 'coverage' => 79.1 }) }
  let(:entity) { described_class.new(report_result, param_type: param_type) }
  let(:param_type) { 'coverage' }

  describe '#as_json' do
    subject { entity.as_json }

    it { is_expected.to include(:date) }

    it { is_expected.not_to include(:group_name) }

    it { is_expected.to include(:coverage) }

    context 'when given param_type is not allowed' do
      let(:param_type) { 'something_else' }

      it { is_expected.not_to include(:coverage) }
      it { is_expected.not_to include(:something_else) }
    end
  end
end
