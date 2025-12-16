# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Stop, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }
  let(:user) { instance_double(User) }

  subject(:status) { described_class.new(core_status) }

  describe '#label' do
    it { expect(status.label).to eq 'manual stop action' }
  end

  describe 'action details' do
    let_it_be(:user, freeze: true) { create(:user) }

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
      it { expect(status.action_path).to include "#{build.id}/play" }
    end

    describe '#action_icon' do
      it { expect(status.action_icon).to eq 'stop' }
    end

    describe '#action_title' do
      it { expect(status.action_title).to eq 'Stop' }
    end

    describe '#action_button_title' do
      it { expect(status.action_button_title).to eq 'Stop this environment' }
    end

    describe '#confirmation_message' do
      context 'when build does not have manual_confirmation' do
        it { expect(status.confirmation_message).to be_nil }
      end

      context 'when build is manual and has manual_confirmation' do
        let(:build) do
          create(:ci_build, :playable, :with_manual_confirmation, project: project)
        end

        it { expect(status.confirmation_message).to eq 'Please confirm. Do you want to proceed?' }
      end
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is playable' do
      context 'when build stops an environment' do
        let(:build) do
          create(:ci_build, :playable, :teardown_environment, project: project)
        end

        it 'is a correct match' do
          is_expected.to be true
        end
      end

      context 'when build does not stop an environment' do
        let(:build) { create(:ci_build, :playable, project: project) }

        it 'does not match' do
          is_expected.to be false
        end
      end
    end

    context 'when build is not playable' do
      let(:build) { create(:ci_build, project: project) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end

  describe '#status_tooltip' do
    it 'does not override status status_tooltip' do
      expect(core_status).to receive(:status_tooltip).and_return('tooltip')

      status.status_tooltip
    end
  end

  describe '#badge_tooltip' do
    let_it_be(:user, freeze: true) { create(:user) }

    let(:build) { create(:ci_build, :playable, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'does not override status badge_tooltip' do
      expect(core_status).to receive(:badge_tooltip)

      status.badge_tooltip
    end
  end
end
