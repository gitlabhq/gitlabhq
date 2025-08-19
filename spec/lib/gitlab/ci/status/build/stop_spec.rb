# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Stop do
  let(:status) { double('core status') }
  let(:user) { double('user') }

  subject do
    described_class.new(status)
  end

  describe '#label' do
    it { expect(subject.label).to eq 'manual stop action' }
  end

  describe 'action details' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build) }
    let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

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
      it { expect(subject.action_path).to include "#{build.id}/play" }
    end

    describe '#action_icon' do
      it { expect(subject.action_icon).to eq 'stop' }
    end

    describe '#action_title' do
      it { expect(subject.action_title).to eq 'Stop' }
    end

    describe '#action_button_title' do
      it { expect(subject.action_button_title).to eq 'Stop this environment' }
    end

    describe '#confirmation_message' do
      context 'when build does not have manual_confirmation' do
        it { expect(subject.confirmation_message).to be_nil }
      end

      context 'when build is manual and has manual_confirmation' do
        let(:build) do
          create(:ci_build, :playable, :with_manual_confirmation)
        end

        it { expect(subject.confirmation_message).to eq 'Please confirm. Do you want to proceed?' }
      end
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is playable' do
      context 'when build stops an environment' do
        let(:build) do
          create(:ci_build, :playable, :teardown_environment)
        end

        it 'is a correct match' do
          expect(subject).to be true
        end
      end

      context 'when build does not stop an environment' do
        let(:build) { create(:ci_build, :playable) }

        it 'does not match' do
          expect(subject).to be false
        end
      end
    end

    context 'when build is not playable' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end

  describe '#status_tooltip' do
    it 'does not override status status_tooltip' do
      expect(status).to receive(:status_tooltip)

      subject.status_tooltip
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :playable) }
    let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'does not override status badge_tooltip' do
      expect(status).to receive(:badge_tooltip)

      subject.badge_tooltip
    end
  end
end
