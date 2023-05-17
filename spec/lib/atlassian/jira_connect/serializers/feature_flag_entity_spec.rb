# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::FeatureFlagEntity, feature_category: :integrations do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create_default(:project) }

  subject { described_class.represent(feature_flag) }

  context 'when the feature flag does not belong to any Jira issue' do
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }

    describe '#issue_keys' do
      it 'is empty' do
        expect(subject.issue_keys).to be_empty
      end
    end

    describe '#to_json' do
      it 'can encode the object' do
        expect(subject.to_json).to be_valid_json
      end

      it 'is invalid, since it has no issue keys' do
        expect(subject.to_json).not_to match_schema(Atlassian::Schemata.feature_flag_info)
      end
    end
  end

  context 'when the feature flag does belong to a Jira issue' do
    let(:feature_flag) do
      create(:operations_feature_flag, project: project, description: 'THING-123')
    end

    describe '#issue_keys' do
      it 'is not empty' do
        expect(subject.issue_keys).not_to be_empty
      end
    end

    describe '#to_json' do
      it 'is valid according to the feature flag info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.feature_flag_info)
      end
    end

    context 'it has a percentage strategy' do
      let!(:scopes) do
        strat = create(
          :operations_strategy,
          feature_flag: feature_flag,
          name: ::Operations::FeatureFlags::Strategy::STRATEGY_GRADUALROLLOUTUSERID,
          parameters: { 'percentage' => '50', 'groupId' => 'abcde' }
        )

        [
          create(:operations_scope, strategy: strat, environment_scope: 'production in live'),
          create(:operations_scope, strategy: strat, environment_scope: 'staging'),
          create(:operations_scope, strategy: strat)
        ]
      end

      let(:entity) { Gitlab::Json.parse(subject.to_json) }

      it 'is valid according to the feature flag info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.feature_flag_info)
      end

      it 'has the correct summary' do
        expect(entity.dig('summary', 'url')).to eq "http://localhost/#{project.full_path}/-/feature_flags/#{feature_flag.iid}/edit"
        expect(entity.dig('summary', 'status')).to eq(
          'enabled' => true,
          'defaultValue' => '',
          'rollout' => { 'percentage' => 50.0, 'text' => 'Percent of users' }
        )
      end

      it 'includes the correct environments' do
        expect(entity['details']).to contain_exactly(
          include('environment' => { 'name' => 'production in live', 'type' => 'production' }),
          include('environment' => { 'name' => 'staging', 'type' => 'staging' }),
          include('environment' => { 'name' => scopes.last.environment_scope })
        )
      end
    end
  end
end
