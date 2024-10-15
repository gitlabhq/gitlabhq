# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ListIssuesService, feature_category: :observability do
  include_context 'sentry error tracking context'

  let(:params) { {} }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with Sentry backend' do
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

        it 'returns bad request with invalid issue_status' do
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

    context 'with integrated error tracking' do
      let(:error_repository) { instance_double(Gitlab::ErrorTracking::ErrorRepository) }
      let(:errors) { [] }
      let(:pagination) { Gitlab::ErrorTracking::ErrorRepository::Pagination.new(nil, nil) }
      let(:opts) { default_opts }

      let(:default_opts) do
        {
          filters: { status: described_class::DEFAULT_ISSUE_STATUS },
          query: nil,
          sort: described_class::DEFAULT_SORT,
          limit: described_class::DEFAULT_LIMIT,
          cursor: nil
        }
      end

      let(:params) { {} }

      before do
        error_tracking_setting.update!(integrated: true)

        allow(service).to receive(:error_repository).and_return(error_repository)
      end

      context 'when errors are found' do
        let(:error) { build_stubbed(:error_tracking_open_api_error, project_id: project.id) }
        let(:errors) { [error] }

        before do
          allow(error_repository).to receive(:list_errors)
            .with(**opts)
            .and_return([errors, pagination])
        end

        context 'without params' do
          it 'returns the errors without pagination' do
            expect(result[:status]).to eq(:success)
            expect(result[:issues]).to eq(errors)
            expect(result[:pagination]).to eq({})
            expect(error_repository).to have_received(:list_errors).with(**opts)
          end
        end

        context 'with pagination' do
          context 'with next page' do
            before do
              pagination.next = 'next cursor'
            end

            it 'has next cursor' do
              expect(result[:pagination]).to eq(next: { cursor: 'next cursor' })
            end
          end

          context 'with prev page' do
            before do
              pagination.prev = 'prev cursor'
            end

            it 'has prev cursor' do
              expect(result[:pagination]).to eq(previous: { cursor: 'prev cursor' })
            end
          end

          context 'with next and prev page' do
            before do
              pagination.next = 'next cursor'
              pagination.prev = 'prev cursor'
            end

            it 'has both cursors' do
              expect(result[:pagination]).to eq(
                next: { cursor: 'next cursor' },
                previous: { cursor: 'prev cursor' }
              )
            end
          end
        end
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
