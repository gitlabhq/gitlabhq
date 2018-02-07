# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170803090603_calculate_conv_dev_index_percentages.rb')

describe CalculateConvDevIndexPercentages, :delete do
  let(:migration) { described_class.new }
  let!(:conv_dev_index) do
    create(:conversational_development_index_metric,
      leader_notes: 0,
      instance_milestones: 0,
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
