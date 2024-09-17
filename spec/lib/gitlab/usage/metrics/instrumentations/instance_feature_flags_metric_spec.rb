# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InstanceFeatureFlagsMetric,
  feature_category: :service_ping do
  context 'with feature flags' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:metric) { described_class.new({ time_frame: 'all', options: { data_source: 'system' } }) }

    describe 'with feature flags' do
      before do
        stub_feature_flag_definition('test_flag')
        stub_feature_flag_definition('off_test_flag')
        stub_feature_flag_definition('test_flag_user')
        stub_feature_flag_definition('test_flag_project')
        stub_feature_flag_definition('test_flag_group')
        stub_feature_flag_definition('test_flag_multiple')

        stub_feature_flags(test_flag: true)
        stub_feature_flags(off_test_flag: false)
        stub_feature_flags(test_flag_user: [user])
        stub_feature_flags(test_flag_project: [project])
        stub_feature_flags(test_flag_group: [group])
        stub_feature_flags(test_flag_multiple: [user, group])
      end

      it 'has correct value' do
        tested_metrics =
          [
            {
              name: 'test_flag',
              status: 'on',
              type: 'development',
              actor_counts: {}
            },
            {
              name: 'off_test_flag',
              status: 'off',
              type: 'development',
              actor_counts: {}
            },
            {
              name: 'test_flag_user',
              status: 'conditional',
              type: 'development',
              actor_counts: { 'users' => 1 }
            },
            {
              name: 'test_flag_group',
              status: 'conditional',
              type: 'development',
              actor_counts: { 'groups' => 1 }
            },
            {
              name: 'test_flag_project',
              status: 'conditional',
              type: 'development',
              actor_counts: { 'projects' => 1 }
            },
            {
              name: 'test_flag_multiple',
              status: 'conditional',
              type: 'development',
              actor_counts: { 'users' => 1, 'groups' => 1 }
            }
          ]

        expect(metric.value).to include(*tested_metrics)
      end
    end
  end
end
