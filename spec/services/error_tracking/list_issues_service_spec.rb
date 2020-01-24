# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ListIssuesService do
  include_context 'sentry error tracking context'

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

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when list_sentry_issues returns issues' do
        let(:issues) { [:list, :of, :issues] }

        before do
          expect(error_tracking_setting)
            .to receive(:list_sentry_issues)
            .with(list_sentry_issues_args)
            .and_return(issues: issues, pagination: {})
        end

        it 'returns the issues' do
          expect(result).to eq(status: :success, pagination: {}, issues: issues)
        end
      end

      include_examples 'error tracking service data not ready', :list_sentry_issues
      include_examples 'error tracking service sentry error handling', :list_sentry_issues
      include_examples 'error tracking service http status handling', :list_sentry_issues
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end

  describe '#external_url' do
    it 'calls the project setting sentry_external_url' do
      expect(error_tracking_setting).to receive(:sentry_external_url).and_return(sentry_url)

      expect(subject.external_url).to eql sentry_url
    end
  end
end
