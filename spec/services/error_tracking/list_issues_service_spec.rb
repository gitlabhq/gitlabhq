# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ListIssuesService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:result) { subject.execute }

  let(:error_tracking_setting) do
    create(:project_error_tracking_setting, api_url: sentry_url, token: token, project: project)
  end

  subject { described_class.new(project, user) }

  before do
    expect(project).to receive(:error_tracking_setting).at_least(:once).and_return(error_tracking_setting)

    project.add_reporter(user)
  end

  describe '#execute' do
    context 'with authorized user' do
      context 'when list_sentry_issues returns issues' do
        let(:issues) { [:list, :of, :issues] }

        before do
          expect(error_tracking_setting)
            .to receive(:list_sentry_issues).and_return(issues: issues)
        end

        it 'returns the issues' do
          expect(result).to eq(status: :success, issues: issues)
        end
      end

      context 'when list_sentry_issues returns nil' do
        before do
          expect(error_tracking_setting)
            .to receive(:list_sentry_issues).and_return(nil)
        end

        it 'result is not ready' do
          expect(result).to eq(
            status: :error, http_status: :no_content, message: 'not ready')
        end
      end
    end

    context 'with unauthorized user' do
      let(:unauthorized_user) { create(:user) }

      subject { described_class.new(project, unauthorized_user) }

      it 'returns error' do
        result = subject.execute

        expect(result).to include(status: :error, message: 'access denied')
      end
    end

    context 'with error tracking disabled' do
      before do
        error_tracking_setting.enabled = false
      end

      it 'raises error' do
        result = subject.execute

        expect(result).to include(status: :error, message: 'not enabled')
      end
    end
  end

  describe '#sentry_external_url' do
    let(:external_url) { 'https://sentrytest.gitlab.com/sentry-org/sentry-project' }

    it 'calls ErrorTracking::ProjectErrorTrackingSetting' do
      expect(error_tracking_setting).to receive(:sentry_external_url).and_call_original

      subject.external_url
    end
  end
end
