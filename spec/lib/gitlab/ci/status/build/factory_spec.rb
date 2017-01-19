require 'spec_helper'

describe Gitlab::Ci::Status::Build::Factory do
  let(:user) { create(:user) }
  let(:project) { build.project }

  subject { described_class.new(build, user) }
  let(:status) { subject.fabricate! }

  before { project.team << [user, :developer] }

  context 'when build is successful' do
    let(:build) { create(:ci_build, :success) }

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'passed'
      expect(status.icon).to eq 'icon_status_success'
      expect(status.label).to eq 'passed'
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is failed' do
    let(:build) { create(:ci_build, :failed) }

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'failed'
      expect(status.icon).to eq 'icon_status_failed'
      expect(status.label).to eq 'failed'
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is a canceled' do
    let(:build) { create(:ci_build, :canceled) }

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'canceled'
      expect(status.icon).to eq 'icon_status_canceled'
      expect(status.label).to eq 'canceled'
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is running' do
    let(:build) { create(:ci_build, :running) }

    it 'fabricates a canceable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Cancelable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'running'
      expect(status.icon).to eq 'icon_status_running'
      expect(status.label).to eq 'running'
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is pending' do
    let(:build) { create(:ci_build, :pending) }

    it 'fabricates a cancelable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Build::Cancelable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'pending'
      expect(status.icon).to eq 'icon_status_pending'
      expect(status.label).to eq 'pending'
      expect(status).to have_details
      expect(status).to have_action
    end
  end

  context 'when build is skipped' do
    let(:build) { create(:ci_build, :skipped) }

    it 'fabricates a core skipped status' do
      expect(status).to be_a Gitlab::Ci::Status::Skipped
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'skipped'
      expect(status.icon).to eq 'icon_status_skipped'
      expect(status.label).to eq 'skipped'
      expect(status).to have_details
      expect(status).not_to have_action
    end
  end

  context 'when build is a manual action' do
    context 'when build is a play action' do
      let(:build) { create(:ci_build, :playable) }

      it 'fabricates a core skipped status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::Play
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq 'manual'
        expect(status.icon).to eq 'icon_status_manual'
        expect(status.label).to eq 'manual play action'
        expect(status).to have_details
        expect(status).to have_action
      end
    end

    context 'when build is an environment stop action' do
      let(:build) { create(:ci_build, :playable, :teardown_environment) }

      it 'fabricates a core skipped status' do
        expect(status).to be_a Gitlab::Ci::Status::Build::Stop
      end

      it 'fabricates status with correct details' do
        expect(status.text).to eq 'manual'
        expect(status.icon).to eq 'icon_status_manual'
        expect(status.label).to eq 'manual stop action'
        expect(status).to have_details
        expect(status).to have_action
      end
    end
  end
end
