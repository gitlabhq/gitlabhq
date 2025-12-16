# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Retryable, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:user, freeze: true) { create(:user) }

  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }

  subject(:status) { described_class.new(core_status) }

  describe '#text' do
    let(:core_status) { double('core status') }

    it 'does not override status text' do
      expect(core_status).to receive(:text)

      status.text
    end
  end

  describe '#icon' do
    it 'does not override status icon' do
      expect(core_status).to receive(:icon)

      status.icon
    end
  end

  describe '#label' do
    it 'does not override status label' do
      expect(core_status).to receive(:label)

      status.label
    end
  end

  describe '#group' do
    it 'does not override status group' do
      expect(core_status).to receive(:group)

      status.group
    end
  end

  describe '#status_tooltip' do
    it 'does not override status status_tooltip' do
      expect(core_status).to receive(:status_tooltip)

      status.status_tooltip
    end
  end

  describe '#badge_tooltip' do
    let(:build) { create(:ci_build, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'does return status' do
      expect(core_status.badge_tooltip).to eq('pending')
    end
  end

  describe 'action details' do
    let(:build) { create(:ci_build, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

    describe '#has_action?' do
      context 'when user is allowed to update build' do
        before do
          stub_not_protect_default_branch

          build.project.add_developer(user)
        end

        it { is_expected.to have_action }
      end

      context 'when user is not allowed to update build' do
        it { is_expected.not_to have_action }
      end
    end

    describe '#action_path' do
      it { expect(status.action_path).to include "#{build.id}/retry" }
    end

    describe '#action_icon' do
      it { expect(status.action_icon).to eq 'retry' }
    end

    describe '#action_title' do
      it { expect(status.action_title).to eq 'Run again' }
    end

    describe '#action_button_title' do
      it { expect(status.action_button_title).to eq 'Run this job again' }
    end

    describe '#confirmation_message' do
      context 'when build does not have manual_confirmation' do
        it { expect(status.confirmation_message).to be_nil }
      end

      context 'when build is manual and has manual_confirmation' do
        let(:build) do
          create(:ci_build, :success, :playable, :with_manual_confirmation, project: project)
        end

        it { expect(status.confirmation_message).to eq 'Please confirm. Do you want to proceed?' }
      end
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is retryable' do
      let(:build) { create(:ci_build, :success, project: project) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not retryable' do
      let(:build) { create(:ci_build, :running, project: project) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end
end
