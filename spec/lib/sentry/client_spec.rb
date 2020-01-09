# frozen_string_literal: true

require 'spec_helper'

describe Sentry::Client do
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }

  subject { Sentry::Client.new(sentry_url, token) }

  it { is_expected.to respond_to :projects }
  it { is_expected.to respond_to :list_issues }
  it { is_expected.to respond_to :issue_details }
  it { is_expected.to respond_to :issue_latest_event }
end
