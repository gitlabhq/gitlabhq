# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170803090603_calculate_conv_dev_index_percentages.rb')

describe CalculateConvDevIndexPercentages, :migration do
  let(:migration) { described_class.new }
  let!(:conv_dev_index) do
    table(:conversational_development_index_metrics).create!(
      leader_issues: 9.256,
      leader_notes: 0,
      leader_milestones: 16.2456,
      leader_boards: 5.2123,
      leader_merge_requests: 1.2,
      leader_ci_pipelines: 12.1234,
      leader_environments: 3.3333,
      leader_deployments: 1.200,
      leader_projects_prometheus_active: 0.111,
      leader_service_desk_issues: 15.891,
      instance_issues: 1.234,
      instance_notes: 28.123,
      instance_milestones: 0,
      instance_boards: 3.254,
      instance_merge_requests: 0.6,
      instance_ci_pipelines: 2.344,
      instance_environments: 2.2222,
      instance_deployments: 0.771,
      instance_projects_prometheus_active: 0.109,
      instance_service_desk_issues: 13.345,
      percentage_issues: 0,
      percentage_notes: 0,
      percentage_milestones: 0,
      percentage_boards: 0,
      percentage_merge_requests: 0,
      percentage_ci_pipelines: 0,
      percentage_environments: 0,
      percentage_deployments: 0,
      percentage_projects_prometheus_active: 0,
      percentage_service_desk_issues: 0)
  end

  describe '#up' do
    it 'calculates percentages correctly' do
      migration.up
      conv_dev_index.reload

      expect(conv_dev_index.percentage_issues).to be_within(0.1).of(13.3)
      expect(conv_dev_index.percentage_notes).to be_zero # leader 0
      expect(conv_dev_index.percentage_milestones).to be_zero # instance 0
      expect(conv_dev_index.percentage_boards).to be_within(0.1).of(62.4)
      expect(conv_dev_index.percentage_merge_requests).to eq(50.0)
      expect(conv_dev_index.percentage_ci_pipelines).to be_within(0.1).of(19.3)
      expect(conv_dev_index.percentage_environments).to be_within(0.1).of(66.7)
      expect(conv_dev_index.percentage_deployments).to be_within(0.1).of(64.2)
      expect(conv_dev_index.percentage_projects_prometheus_active).to be_within(0.1).of(98.2)
      expect(conv_dev_index.percentage_service_desk_issues).to be_within(0.1).of(84.0)
    end
  end
end
