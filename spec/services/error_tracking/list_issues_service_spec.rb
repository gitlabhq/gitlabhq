# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ListIssuesService, feature_category: :error_tracking do
  include_context 'sentry error tracking context'

  let(:params) { {} }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'Sentry backend' do
      let(:params) { { search_term: 'something', sort: 'last_seen', cursor: 'some-cursor' } }

      let(:list_sentry_issues_args) do
        {
          issue_status: 'unresolved',
          limit: 20,
          search_term: 'something',
          sort: 'last_seen',
          cursor: 'some-cursor'
        }
      end

      context 'with authorized user' do
        let(:issues) { [] }

        described_class::ISSUE_STATUS_VALUES.each do |status|
          it "returns the issues with #{status} issue_status" do
            params[:issue_status] = status
            list_sentry_issues_args[:issue_status] = status
            expect_list_sentry_issues_with(list_sentry_issues_args)

            expect(result).to eq(status: :success, pagination: {}, issues: issues)
          end
        end

        it 'returns the issues with no issue_status' do
          expect_list_sentry_issues_with(list_sentry_issues_args)

          expect(result).to eq(status: :success, pagination: {}, issues: issues)
        end

        it 'returns bad request for an issue_status not on the whitelist' do
          params[:issue_status] = 'assigned'

          expect(error_tracking_setting).not_to receive(:list_sentry_issues)
          expect(result).to eq(message: "Bad Request: Invalid issue_status", status: :error, http_status: :bad_request)
        end

        include_examples 'error tracking service data not ready', :list_sentry_issues
        include_examples 'error tracking service sentry error handling', :list_sentry_issues
        include_examples 'error tracking service http status handling', :list_sentry_issues
      end

      include_examples 'error tracking service unauthorized user'
      include_examples 'error tracking service disabled'

      def expect_list_sentry_issues_with(list_sentry_issues_args)
        expect(error_tracking_setting)
          .to receive(:list_sentry_issues)
          .with(list_sentry_issues_args)
          .and_return(issues: [], pagination: {})
      end
    end

    context 'GitLab backend' do
      let_it_be(:error1) { create(:error_tracking_error, name: 'foo', project: project) }
      let_it_be(:error2) { create(:error_tracking_error, name: 'bar', project: project) }

      let(:params) { { limit: '1' } }

      before do
        error_tracking_setting.update!(integrated: true)
      end

      it 'returns the error in expected format' do
        expect(result[:status]).to eq(:success)
        expect(result[:issues].size).to eq(1)
        expect(result[:issues].first.to_json).to eq(error2.to_sentry_error.to_json)
        expect(result[:pagination][:next][:cursor]).to be_present
        expect(result[:pagination][:previous]).to be_nil
      end
    end
  end

  describe '#external_url' do
    it 'calls the project setting sentry_external_url' do
      expect(error_tracking_setting).to receive(:sentry_external_url).and_return(sentry_url)

      expect(subject.external_url).to eql sentry_url
    end
  end
end
