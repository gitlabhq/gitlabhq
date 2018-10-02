# frozen_string_literal: true
require 'spec_helper'

describe Ci::ProcessBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { described_class.new(project, user).execute(build, current_status) }

  before do
    project.add_maintainer(user)
  end

  shared_examples_for 'Enqueuing properly' do |valid_statuses_for_when|
    valid_statuses_for_when.each do |status_for_prior_stages|
      context "when status for prior stages is #{status_for_prior_stages}" do
        let(:current_status) { status_for_prior_stages }

        %w[created skipped manual scheduled].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, when: when_option, user: user, project: project) }

            it 'enqueues the build' do
              expect { subject }.to change { build.status }.to('pending')
            end
          end
        end

        %w[pending running success failed canceled].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, when: when_option, user: user, project: project) }

            it 'does not change the build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end

    (HasStatus::AVAILABLE_STATUSES - valid_statuses_for_when).each do |status_for_prior_stages|
      let(:current_status) { status_for_prior_stages }

      context "when status for prior stages is #{status_for_prior_stages}" do
        %w[created pending].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, when: when_option, user: user, project: project) }

            it 'skips the build' do
              expect { subject }.to change { build.status }.to('skipped')
            end
          end
        end

        (HasStatus::AVAILABLE_STATUSES - %w[created pending]).each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, when: when_option, user: user, project: project) }

            it 'does not change build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end
  end

  shared_examples_for 'Actionizing properly' do |valid_statuses_for_when|
    valid_statuses_for_when.each do |status_for_prior_stages|
      context "when status for prior stages is #{status_for_prior_stages}" do
        let(:current_status) { status_for_prior_stages }

        %w[created].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :actionable, user: user, project: project) }

            it 'enqueues the build' do
              expect { subject }.to change { build.status }.to('manual')
            end
          end
        end

        %w[manual skipped pending running success failed canceled scheduled].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :actionable, user: user, project: project) }

            it 'does not change the build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end

    (HasStatus::AVAILABLE_STATUSES - valid_statuses_for_when).each do |status_for_prior_stages|
      let(:current_status) { status_for_prior_stages }

      context "when status for prior stages is #{status_for_prior_stages}" do
        %w[created pending].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :actionable, user: user, project: project) }

            it 'skips the build' do
              expect { subject }.to change { build.status }.to('skipped')
            end
          end
        end

        (HasStatus::AVAILABLE_STATUSES - %w[created pending]).each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :actionable, user: user, project: project) }

            it 'does not change build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end
  end

  shared_examples_for 'Scheduling properly' do |valid_statuses_for_when|
    valid_statuses_for_when.each do |status_for_prior_stages|
      context "when status for prior stages is #{status_for_prior_stages}" do
        let(:current_status) { status_for_prior_stages }

        %w[created].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :schedulable, user: user, project: project) }

            it 'enqueues the build' do
              expect { subject }.to change { build.status }.to('scheduled')
            end
          end
        end

        %w[manual skipped pending running success failed canceled scheduled].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :schedulable, user: user, project: project) }

            it 'does not change the build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end

    (HasStatus::AVAILABLE_STATUSES - valid_statuses_for_when).each do |status_for_prior_stages|
      let(:current_status) { status_for_prior_stages }

      context "when status for prior stages is #{status_for_prior_stages}" do
        %w[created pending].each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :schedulable, user: user, project: project) }

            it 'skips the build' do
              expect { subject }.to change { build.status }.to('skipped')
            end
          end
        end

        (HasStatus::AVAILABLE_STATUSES - %w[created pending]).each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, :schedulable, user: user, project: project) }

            it 'does not change build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end
  end

  context 'when build has on_success option' do
    let(:when_option) { :on_success }

    it_behaves_like 'Enqueuing properly', %w[success skipped]
  end

  context 'when build has on_failure option' do
    let(:when_option) { :on_failure }

    it_behaves_like 'Enqueuing properly', %w[failed]
  end

  context 'when build has always option' do
    let(:when_option) { :always }

    it_behaves_like 'Enqueuing properly', %w[success failed skipped]
  end

  context 'when build has manual option' do
    let(:when_option) { :manual }

    it_behaves_like 'Actionizing properly', %w[success skipped]
  end

  context 'when build has delayed option' do
    let(:when_option) { :delayed }

    before do
      allow(Ci::BuildScheduleWorker).to receive(:perform_at) { }
    end

    context 'when ci_enable_scheduled_build is enabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: true)
      end

      it_behaves_like 'Scheduling properly', %w[success skipped]
    end

    context 'when ci_enable_scheduled_build is enabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: false)
      end

      it_behaves_like 'Actionizing properly', %w[success skipped]
    end
  end
end
