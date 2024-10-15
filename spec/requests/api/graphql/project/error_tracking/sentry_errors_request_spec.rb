# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'sentry errors requests', feature_category: :observability do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:project_setting) { create(:project_error_tracking_setting, project: project) }
  let_it_be(:current_user) { project.first_owner }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('sentryErrors', {}, fields)
    )
  end

  describe 'getting a detailed sentry error' do
    let_it_be(:sentry_detailed_error) { build(:error_tracking_sentry_detailed_error) }

    let(:sentry_gid) { sentry_detailed_error.to_global_id.to_s }

    let(:detailed_fields) do
      all_graphql_fields_for('SentryDetailedError'.classify)
    end

    let(:fields) do
      query_graphql_field('detailedError', { id: sentry_gid }, detailed_fields)
    end

    let(:error_data) { graphql_data.dig('project', 'sentryErrors', 'detailedError') }

    it 'returns a successful response', :aggregate_failures do
      post_graphql(query, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(json_response.keys).to include('data')
    end

    context 'when data is loading via reactive cache' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it 'is expected to return an empty error' do
        expect(error_data).to be_nil
      end
    end

    context 'when reactive cache returns data' do
      before do
        stub_setting_for(:issue_details, issue: sentry_detailed_error)

        post_graphql(query, current_user: current_user)
      end

      let(:sentry_error) { sentry_detailed_error }
      let(:error) { error_data }

      it_behaves_like 'setting sentry error data'

      it 'is expected to return the frequency correctly' do
        aggregate_failures 'it returns the frequency correctly' do
          expect(error_data['frequency'].count).to eql sentry_detailed_error.frequency.count

          first_frequency = error_data['frequency'].first
          expect(Time.parse(first_frequency['time'])).to eql Time.at(sentry_detailed_error.frequency[0][0], in: 0)
          expect(first_frequency['count']).to eql sentry_detailed_error.frequency[0][1]
        end
      end

      context 'when user does not have permission' do
        let(:current_user) { create(:user) }

        it 'is expected to return an empty error' do
          expect(error_data).to be_nil
        end
      end
    end

    context 'when sentry api returns an error' do
      before do
        stub_setting_for(:issue_details, error: 'error message')

        post_graphql(query, current_user: current_user)
      end

      it 'is expected to handle the error and return nil' do
        expect(error_data).to be_nil
      end
    end
  end

  describe 'getting an errors list' do
    let_it_be(:sentry_error) { build(:error_tracking_sentry_error) }
    let_it_be(:pagination) do
      {
        'next' => { 'cursor' => '2222' },
        'previous' => { 'cursor' => '1111' }
      }
    end

    let(:fields) do
      <<~QUERY
          errors {
            nodes {
              #{all_graphql_fields_for('SentryError'.classify)}
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
      QUERY
    end

    let(:error_data) { graphql_data.dig('project', 'sentryErrors', 'errors', 'nodes') }
    let(:pagination_data) { graphql_data.dig('project', 'sentryErrors', 'errors', 'pageInfo') }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    context 'when data is loading via reactive cache' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it 'is expected to return nil' do
        expect(error_data).to be_nil
      end
    end

    context 'when reactive cache returns data' do
      before do
        stub_setting_for(:list_sentry_issues, issues: [sentry_error], pagination: pagination)

        post_graphql(query, current_user: current_user)
      end

      let(:error) { error_data.first }

      it 'is expected to return an array of data' do
        expect(error_data).to be_a Array
        expect(error_data.count).to eq 1
      end

      it_behaves_like 'setting sentry error data'

      it 'sets the pagination correctly' do
        expect(pagination_data['startCursor']).to eq(pagination['previous']['cursor'])
        expect(pagination_data['endCursor']).to eq(pagination['next']['cursor'])
      end

      it 'is expected to return the frequency correctly' do
        aggregate_failures 'it returns the frequency correctly' do
          error = error_data.first

          expect(error['frequency'].count).to eql sentry_error.frequency.count

          first_frequency = error['frequency'].first

          expect(Time.parse(first_frequency['time'])).to eql Time.at(sentry_error.frequency[0][0], in: 0)
          expect(first_frequency['count']).to eql sentry_error.frequency[0][1]
        end
      end
    end

    context 'when sentry api itself errors out' do
      before do
        stub_setting_for(:list_sentry_issues, error: 'error message')

        post_graphql(query, current_user: current_user)
      end

      it 'is expected to handle the error and return nil' do
        expect(error_data).to be_nil
      end
    end
  end

  describe 'getting a stack trace' do
    let_it_be(:sentry_stack_trace) { build(:error_tracking_sentry_error_event) }

    let(:sentry_gid) { global_id_of(Gitlab::ErrorTracking::DetailedError.new(id: 1)) }

    let(:stack_trace_fields) do
      all_graphql_fields_for('SentryErrorStackTrace'.classify)
    end

    let(:fields) do
      query_graphql_field('errorStackTrace', { id: sentry_gid }, stack_trace_fields)
    end

    let(:stack_trace_data) { graphql_data.dig('project', 'sentryErrors', 'errorStackTrace') }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    context 'when data is loading via reactive cache' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it 'is expected to return an empty error' do
        expect(stack_trace_data).to be_nil
      end
    end

    context 'when reactive cache returns data' do
      before do
        stub_setting_for(:issue_latest_event, latest_event: sentry_stack_trace)

        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'setting stack trace error'

      context 'when user does not have permission' do
        let(:current_user) { create(:user) }

        it 'is expected to return an empty error' do
          expect(stack_trace_data).to be_nil
        end
      end
    end

    context 'when sentry api returns an error' do
      before do
        stub_setting_for(:issue_latest_event, error: 'error message')

        post_graphql(query, current_user: current_user)
      end

      it 'is expected to handle the error and return nil' do
        expect(stack_trace_data).to be_nil
      end
    end
  end

  private

  def stub_setting_for(method, **return_value)
    allow_next_found_instance_of(ErrorTracking::ProjectErrorTrackingSetting) do |setting|
      allow(setting).to receive(method).and_return(**return_value)
    end
  end
end
