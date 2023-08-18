# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/show' do
  include_context 'project show action'

  context 'when the issue is related to a sentry error' do
    it 'renders a stack trace' do
      sentry_issue = double(:sentry_issue, sentry_issue_identifier: '1066622')
      allow(issue).to receive(:sentry_issue).and_return(sentry_issue)
      render

      expect(rendered).to have_selector(
        "#js-sentry-error-stack-trace"\
        "[data-issue-stack-trace-path="\
        "\"/#{project.full_path}/-/error_tracking/1066622/stack_trace.json\"]"
      )
    end
  end

  context 'when the issue is not related to a sentry error' do
    it 'does not render a stack trace' do
      render

      expect(rendered).not_to have_selector('#js-sentry-error-stack-trace')
    end
  end
end
