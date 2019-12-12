# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Build::Factory do
  let(:user) { create(:user) }
  let(:project) { build.project }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(build, user) }

  before do
    stub_not_protect_default_branch

    project.add_developer(user)
  end

  context 'when build is successful' do
    let(:build) { create(:ci_build, :success, :trace_artifact) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Retryable]
    end

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|passed')
      expect(status.icon).to eq 'status_success'
      expect(status.favicon).to eq 'favicon_status_success'
      expect(status.label).to eq s_('CiStatusLabel|passed')
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is erased' do
    let(:build) { create(:ci_build, :success, :erased) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Erased,
                Gitlab::Ci::Status::Build::Retryable]
    end

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|passed')
      expect(status.icon).to eq 'status_success'
      expect(status.favicon).to eq 'favicon_status_success'
      expect(status.label).to eq s_('CiStatusLabel|passed')
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is failed' do
    context 'when build is not allowed to fail' do
      let(:build) { create(:ci_build, :failed) }

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Failed
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Build::Retryable,
                  Gitlab::Ci::Status::Build::Failed]
      end

      it 'fabricates a failed build status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::Failed
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq s_('CiStatusText|failed')
        expect(status.icon).to eq 'status_failed'
        expect(status.favicon).to eq 'favicon_status_failed'
        expect(status.label).to eq s_('CiStatusLabel|failed')
        expect(status.status_tooltip).to eq "#{s_('CiStatusText|failed')} - (unknown failure)"
        expect(status).to have_details
        expect(status).to have_action
      end
    end

    context 'when build is allowed to fail' do
      let(:build) { create(:ci_build, :failed, :allowed_to_fail, :trace_artifact) }

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Failed
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Build::Retryable,
                  Gitlab::Ci::Status::Build::Failed,
                  Gitlab::Ci::Status::Build::FailedAllowed]
      end

      it 'fabricates a failed but allowed build status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::FailedAllowed
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq s_('CiStatusText|failed')
        expect(status.icon).to eq 'status_warning'
        expect(status.favicon).to eq 'favicon_status_failed'
        expect(status.label).to eq 'failed (allowed to fail)'
        expect(status).to have_details
        expect(status).to have_action
        expect(status.action_title).to include 'Retry'
        expect(status.action_path).to include 'retry'
      end
    end

    context 'when build has unmet prerequisites' do
      let(:build) { create(:ci_build, :prerequisite_failure) }

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Failed
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Build::Retryable,
                  Gitlab::Ci::Status::Build::FailedUnmetPrerequisites]
      end

      it 'fabricates a failed with unmet prerequisites build status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::FailedUnmetPrerequisites
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq s_('CiStatusText|failed')
        expect(status.icon).to eq 'status_failed'
        expect(status.favicon).to eq 'favicon_status_failed'
        expect(status.label).to eq s_('CiStatusLabel|failed')
        expect(status).to have_details
        expect(status).to have_action
        expect(status.action_title).to include 'Retry'
        expect(status.action_path).to include 'retry'
      end
    end
  end

  context 'when build is a canceled' do
    let(:build) { create(:ci_build, :canceled) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Canceled
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Canceled, Gitlab::Ci::Status::Build::Retryable]
    end

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|canceled')
      expect(status.icon).to eq 'status_canceled'
      expect(status.favicon).to eq 'favicon_status_canceled'
      expect(status.illustration).to include(:image, :size, :title)
      expect(status.label).to eq s_('CiStatusLabel|canceled')
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is running' do
    let(:build) { create(:ci_build, :running) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Running
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Cancelable]
    end

    it 'fabricates a canceable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Cancelable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatus|running')
      expect(status.icon).to eq 'status_running'
      expect(status.favicon).to eq 'favicon_status_running'
      expect(status.label).to eq s_('CiStatus|running')
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is pending' do
    let(:build) { create(:ci_build, :pending) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Pending
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Pending, Gitlab::Ci::Status::Build::Cancelable]
    end

    it 'fabricates a cancelable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Cancelable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|pending')
      expect(status.icon).to eq 'status_pending'
      expect(status.favicon).to eq 'favicon_status_pending'
      expect(status.illustration).to include(:image, :size, :title, :content)
      expect(status.label).to eq s_('CiStatusLabel|pending')
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is skipped' do
    let(:build) { create(:ci_build, :skipped) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Skipped
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses).to eq [Gitlab::Ci::Status::Build::Skipped]
    end

    it 'fabricates a skipped build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Skipped
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|skipped')
      expect(status.icon).to eq 'status_skipped'
      expect(status.favicon).to eq 'favicon_status_skipped'
      expect(status.illustration).to include(:image, :size, :title)
      expect(status.label).to eq s_('CiStatusLabel|skipped')
      expect(status).to have_details
      expect(status).not_to have_action
    end
  end

  context 'when build is a manual action' do
    context 'when build is a play action' do
      let(:build) { create(:ci_build, :playable) }

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Manual
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Build::Manual,
                  Gitlab::Ci::Status::Build::Play,
                  Gitlab::Ci::Status::Build::Action]
      end

      it 'fabricates action detailed status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::Action
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq s_('CiStatusText|manual')
        expect(status.group).to eq 'manual'
        expect(status.icon).to eq 'status_manual'
        expect(status.favicon).to eq 'favicon_status_manual'
        expect(status.illustration).to include(:image, :size, :title, :content)
        expect(status.label).to include 'manual play action'
        expect(status).to have_details
        expect(status.action_path).to include 'play'
      end

      context 'when user has ability to play action' do
        it 'fabricates status that has action' do
          expect(status).to have_action
        end
      end

      context 'when user does not have ability to play action' do
        before do
          allow(build.project).to receive(:empty_repo?).and_return(false)

          create(:protected_branch, :no_one_can_push,
                 name: build.ref, project: build.project)
        end

        it 'fabricates status that has no action' do
          expect(status).not_to have_action
        end
      end
    end

    context 'when build is an environment stop action' do
      let(:build) { create(:ci_build, :playable, :teardown_environment) }

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Manual
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [Gitlab::Ci::Status::Build::Manual,
                  Gitlab::Ci::Status::Build::Stop,
                  Gitlab::Ci::Status::Build::Action]
      end

      it 'fabricates action detailed status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::Action
      end

      context 'when user is not allowed to execute manual action' do
        before do
          allow(build.project).to receive(:empty_repo?).and_return(false)

          create(:protected_branch, :no_one_can_push,
                 name: build.ref, project: build.project)
        end

        it 'fabricates status with correct details' do
          expect(status.text).to eq s_('CiStatusText|manual')
          expect(status.group).to eq 'manual'
          expect(status.icon).to eq 'status_manual'
          expect(status.favicon).to eq 'favicon_status_manual'
          expect(status.label).to eq 'manual stop action (not allowed)'
          expect(status).to have_details
          expect(status).not_to have_action
        end
      end
    end
  end

  context 'when build is a delayed action' do
    let(:build) { create(:ci_build, :scheduled) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Scheduled
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Build::Scheduled,
                Gitlab::Ci::Status::Build::Unschedule,
                Gitlab::Ci::Status::Build::Action]
    end

    it 'fabricates action detailed status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Action
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|delayed')
      expect(status.group).to eq 'scheduled'
      expect(status.icon).to eq 'status_scheduled'
      expect(status.favicon).to eq 'favicon_status_scheduled'
      expect(status.illustration).to include(:image, :size, :title, :content)
      expect(status.label).to include 'unschedule action'
      expect(status).to have_details
      expect(status.action_path).to include 'unschedule'
    end

    context 'when user has ability to play action' do
      it 'fabricates status that has action' do
        expect(status).to have_action
      end
    end

    context 'when user does not have ability to play action' do
      before do
        allow(build.project).to receive(:empty_repo?).and_return(false)

        create(:protected_branch, :no_one_can_push,
                name: build.ref, project: build.project)
      end

      it 'fabricates status that has no action' do
        expect(status).not_to have_action
      end
    end
  end
end
