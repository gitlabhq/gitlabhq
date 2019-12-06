# frozen_string_literal: true
require 'spec_helper'

describe 'getting a detailed sentry error' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:project_setting) { create(:project_error_tracking_setting, project: project) }
  let_it_be(:current_user) { project.owner }
  let_it_be(:sentry_detailed_error) { build(:detailed_error_tracking_error) }
  let(:sentry_gid) { sentry_detailed_error.to_global_id.to_s }
  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('SentryDetailedError'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('sentryDetailedError', { id: sentry_gid }, fields)
    )
  end

  let(:error_data) { graphql_data['project']['sentryDetailedError'] }

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when data is loading via reactive cache' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it "is expected to return an empty error" do
      expect(error_data).to eq nil
    end
  end

  context 'reactive cache returns data' do
    before do
      expect_any_instance_of(ErrorTracking::ProjectErrorTrackingSetting)
        .to receive(:issue_details)
        .and_return({ issue: sentry_detailed_error })

      post_graphql(query, current_user: current_user)
    end

    it "is expected to return a valid error" do
      expect(error_data['id']).to eql sentry_gid
      expect(error_data['sentryId']).to eql sentry_detailed_error.id.to_s
      expect(error_data['status']).to eql sentry_detailed_error.status.upcase
      expect(error_data['firstSeen']).to eql sentry_detailed_error.first_seen
      expect(error_data['lastSeen']).to eql sentry_detailed_error.last_seen
    end

    it 'is expected to return the frequency correctly' do
      expect(error_data['frequency'].count).to eql sentry_detailed_error.frequency.count

      first_frequency = error_data['frequency'].first
      expect(Time.parse(first_frequency['time'])).to eql Time.at(sentry_detailed_error.frequency[0][0], in: 0)
      expect(first_frequency['count']).to eql sentry_detailed_error.frequency[0][1]
    end
  end
end
