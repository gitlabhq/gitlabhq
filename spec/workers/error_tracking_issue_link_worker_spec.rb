# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTrackingIssueLinkWorker do
  let_it_be(:error_tracking) { create(:project_error_tracking_setting) }
  let_it_be(:project) { error_tracking.project }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:sentry_issue) { create(:sentry_issue, issue: issue) }

  let(:repo) do
    Gitlab::ErrorTracking::Repo.new(
      status: 'active',
      integration_id: 66666,
      project_id: project.id
    )
  end

  subject { described_class.new.perform(issue.id) }

  describe '#perform' do
    it 'creates a link between an issue and a Sentry issue in Sentry' do
      expect_next_instance_of(ErrorTracking::SentryClient) do |client|
        expect(client).to receive(:repos).with('sentry-org').and_return([repo])
        expect(client)
          .to receive(:create_issue_link)
          .with(66666, sentry_issue.sentry_issue_identifier, issue)
          .and_return(true)
      end

      expect(subject).to be true
    end

    shared_examples_for 'makes no external API requests' do
      it 'takes no action' do
        expect_any_instance_of(ErrorTracking::SentryClient).not_to receive(:repos)
        expect_any_instance_of(ErrorTracking::SentryClient).not_to receive(:create_issue_link)

        expect(subject).to be nil
      end
    end

    shared_examples_for 'attempts to create a link via plugin' do
      it 'takes no action' do
        expect_next_instance_of(ErrorTracking::SentryClient) do |client|
          expect(client).to receive(:repos).with('sentry-org').and_return([repo])
          expect(client)
            .to receive(:create_issue_link)
            .with(nil, sentry_issue.sentry_issue_identifier, issue)
            .and_return(true)
        end

        expect(subject).to be true
      end
    end

    context 'when issue is unavailable' do
      let(:issue) { double('issue', id: -3) }

      it_behaves_like 'makes no external API requests'
    end

    context 'when project does not have error tracking configured' do
      let(:issue) { build(:project) }

      it_behaves_like 'makes no external API requests'
    end

    context 'when the issue is not linked to a Sentry issue in GitLab' do
      let(:issue) { build(:issue, project: project) }

      it_behaves_like 'makes no external API requests'
    end

    context 'when Sentry disabled the GitLab integration' do
      let(:repo) do
        Gitlab::ErrorTracking::Repo.new(
          status: 'inactive',
          integration_id: 66666,
          project_id: project.id
        )
      end

      it_behaves_like 'attempts to create a link via plugin'
    end

    context 'when Sentry the GitLab integration is for another project' do
      let(:repo) do
        Gitlab::ErrorTracking::Repo.new(
          status: 'active',
          integration_id: 66666,
          project_id: -3
        )
      end

      it_behaves_like 'attempts to create a link via plugin'
    end

    context 'when Sentry repos request errors' do
      it 'falls back to creating a link via plugin' do
        expect_next_instance_of(ErrorTracking::SentryClient) do |client|
          expect(client).to receive(:repos).with('sentry-org').and_raise(ErrorTracking::SentryClient::Error)
          expect(client)
            .to receive(:create_issue_link)
            .with(nil, sentry_issue.sentry_issue_identifier, issue)
            .and_return(true)
        end

        expect(subject).to be true
      end
    end
  end
end
