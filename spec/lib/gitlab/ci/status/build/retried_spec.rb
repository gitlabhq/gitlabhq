# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Retried, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:build) { create(:ci_build, :retried, project: project) }
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
      expect(core_status).to receive(:icon)

      status.icon
    end
  end

  describe '#group' do
    it 'does not override status group' do
      expect(core_status).to receive(:group)

      status.group
    end
  end

  describe '#favicon' do
    it 'does not override status favicon' do
      expect(core_status).to receive(:favicon)

      status.favicon
    end
  end

  describe '#label' do
    it 'does not override status label' do
      expect(core_status).to receive(:label)

      status.label
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :retried, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Success.new(build, user) }

    it 'returns status' do
      expect(status.badge_tooltip).to eq('pending')
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }

    context 'with a failed build' do
      let(:build) { create(:ci_build, :failed, :retried, project: project) }
      let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
      let(:core_status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }

      it 'does override status_tooltip' do
        expect(status.status_tooltip).to eq 'Failed - (unknown failure) (retried)'
      end
    end

    context 'with another build' do
      let(:build) { create(:ci_build, :retried, project: project) }
      let(:core_status) { Gitlab::Ci::Status::Success.new(build, user) }

      it 'does override status_tooltip' do
        expect(status.status_tooltip).to eq 'passed (retried)'
      end
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'with a retried build' do
      it { is_expected.to be true }
    end

    context 'with a build that has not been retried' do
      let(:build) { create(:ci_build, :success, project: project) }

      it { is_expected.to be false }
    end
  end
end
