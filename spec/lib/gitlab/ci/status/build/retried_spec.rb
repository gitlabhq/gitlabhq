# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Retried do
  let(:build) { create(:ci_build, :retried) }
  let(:status) { double('core status') }
  let(:user) { double('user') }

  subject { described_class.new(status) }

  describe '#text' do
    it 'does not override status text' do
      expect(status).to receive(:text)

      subject.text
    end
  end

  describe '#icon' do
    it 'does not override status icon' do
      expect(status).to receive(:icon)

      subject.icon
    end
  end

  describe '#group' do
    it 'does not override status group' do
      expect(status).to receive(:group)

      subject.group
    end
  end

  describe '#favicon' do
    it 'does not override status label' do
      expect(status).to receive(:favicon)

      subject.favicon
    end
  end

  describe '#label' do
    it 'does not override status label' do
      expect(status).to receive(:label)

      subject.label
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :retried) }
    let(:status) { Gitlab::Ci::Status::Success.new(build, user) }

    it 'returns status' do
      expect(status.badge_tooltip).to eq('pending')
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }

    context 'with a failed build' do
      let(:build) { create(:ci_build, :failed, :retried) }
      let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
      let(:status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }

      it 'does override status_tooltip' do
        expect(subject.status_tooltip).to eq 'Failed - (unknown failure) (retried)'
      end
    end

    context 'with another build' do
      let(:build) { create(:ci_build, :retried) }
      let(:status) { Gitlab::Ci::Status::Success.new(build, user) }

      it 'does override status_tooltip' do
        expect(subject.status_tooltip).to eq 'passed (retried)'
      end
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'with a retried build' do
      it { is_expected.to be_truthy }
    end

    context 'with a build that has not been retried' do
      let(:build) { create(:ci_build, :success) }

      it { is_expected.to be_falsy }
    end
  end
end
