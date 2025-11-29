# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Unschedule, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:user, freeze: true) { create(:user) }

  let(:build) { create(:ci_build, :scheduled, project: project) }
  let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

  subject(:status) { described_class.new(core_status) }

  describe '#label' do
    it { expect(status.label).to eq 'unschedule action' }
  end

  describe 'action details' do
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
      it { expect(status.action_path).to include "#{build.id}/unschedule" }
    end

    describe '#action_icon' do
      it { expect(status.action_icon).to eq 'time-out' }
    end

    describe '#action_title' do
      it { expect(status.action_title).to eq 'Unschedule' }
    end

    describe '#action_button_title' do
      it { expect(status.action_button_title).to eq 'Unschedule job' }
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is scheduled' do
      context 'when build unschedules a delayed job' do
        let(:build) { create(:ci_build, :scheduled, project: project) }

        it 'is a correct match' do
          is_expected.to be true
        end
      end

      context 'when build unschedules a normal job' do
        let(:build) { create(:ci_build, project: project) }

        it 'does not match' do
          is_expected.to be false
        end
      end
    end
  end

  describe '#status_tooltip' do
    let(:core_status) { Gitlab::Ci::Status::Scheduled.new(build, user) }

    it 'does not override status status_tooltip' do
      expect(status.status_tooltip).to eq(core_status.status_tooltip)
    end
  end

  describe '#badge_tooltip' do
    it 'does not override status badge_tooltip' do
      expect(status.badge_tooltip).to eq(core_status.badge_tooltip)
    end
  end
end
