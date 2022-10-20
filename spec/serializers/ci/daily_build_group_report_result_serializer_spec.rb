# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultSerializer do
  let(:report_result) do
    [
      double(date: '2020-05-20', group_name: 'rspec', data: { 'coverage' => 79.1 }),
      double(date: '2020-05-20', group_name: 'karma', data: { 'coverage' => 90.1 }),
      double(date: '2020-05-19', group_name: 'rspec', data: { 'coverage' => 77.1 }),
      double(date: '2020-05-19', group_name: 'karma', data: { 'coverage' => 89.1 })
    ]
  end

  let(:serializer) { described_class.new.represent(report_result, param_type: 'coverage') }

  describe '#to_json' do
    let(:json) { Gitlab::Json.parse(serializer.to_json) }

    it 'returns an array of group results' do
      expect(json).to eq(
        [
          {
            'group_name' => 'rspec',
            'data' => [
              { 'date' => '2020-05-20', 'coverage' => 79.1 },
              { 'date' => '2020-05-19', 'coverage' => 77.1 }
            ]
          },
          {
            'group_name' => 'karma',
            'data' => [
              { 'date' => '2020-05-20', 'coverage' => 90.1 },
              { 'date' => '2020-05-19', 'coverage' => 89.1 }
            ]
          }
        ])
    end
  end
end
