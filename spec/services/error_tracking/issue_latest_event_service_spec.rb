# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueLatestEventService do
  include_context 'sentry error tracking context'

  subject { described_class.new(project, user) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when issue_latest_event returns an error event' do
        let(:error_event) { build(:error_tracking_error_event) }

        before do
          expect(error_tracking_setting)
            .to receive(:issue_latest_event).and_return(latest_event: error_event)
        end

        it 'returns the error event' do
          expect(result).to eq(status: :success, latest_event: error_event)
        end
      end

      include_examples 'error tracking service data not ready', :issue_latest_event
      include_examples 'error tracking service sentry error handling', :issue_latest_event
      include_examples 'error tracking service http status handling', :issue_latest_event
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end
