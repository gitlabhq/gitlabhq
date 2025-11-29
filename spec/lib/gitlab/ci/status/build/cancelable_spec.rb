# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Cancelable, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }
  let(:user) { instance_double(User) }

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
      expect(core_status).to receive(:icon).and_return('icon')

      status.icon
    end
  end

  describe '#label' do
    it 'does not override status label' do
      expect(core_status).to receive(:label).and_return('label')

      status.label
    end
  end

  describe '#group' do
    it 'does not override status group' do
      expect(core_status).to receive(:group).and_return('group')

      status.group
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

    let(:build) { create(:ci_build, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'returns the status' do
      expect(status.badge_tooltip).to eq('pending')
    end
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
      it { expect(status.action_path).to include "#{build.id}/cancel" }
    end

    describe '#action_icon' do
      it { expect(status.action_icon).to eq 'cancel' }
    end

    describe '#action_title' do
      it { expect(status.action_title).to eq 'Cancel' }
    end

    describe '#action_button_title' do
      it { expect(status.action_button_title).to eq 'Cancel this job' }
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is cancelable' do
      let(:build) { create(:ci_build, :running, project: project) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not cancelable' do
      let(:build) { create(:ci_build, :success, project: project) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end
end
