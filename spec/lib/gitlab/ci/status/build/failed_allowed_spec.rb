require 'spec_helper'

describe Gitlab::Ci::Status::Build::FailedAllowed do
  let(:status) { double('core status') }
  let(:user) { double('user') }
  let(:build) { create(:ci_build, :failed, :allowed_to_fail) }

  subject do
    described_class.new(status)
  end

  describe '#text' do
    it 'does not override status text' do
      expect(status).to receive(:text)

      subject.text
    end
  end

  describe '#icon' do
    it 'returns a warning icon' do
      expect(subject.icon).to eq 'status_warning'
    end
  end

  describe '#label' do
    it 'returns information about failed but allowed to fail status' do
      expect(subject.label).to eq 'failed (allowed to fail)'
    end
  end

  describe '#group' do
    it 'returns status failed with warnings status group' do
      expect(subject.group).to eq 'failed_with_warnings'
    end
  end

  describe 'action details' do
    describe '#has_action?' do
      it 'does not decorate action details' do
        expect(status).to receive(:has_action?)

        subject.has_action?
      end
    end

    describe '#action_path' do
      it 'does not decorate action path' do
        expect(status).to receive(:action_path)

        subject.action_path
      end
    end

    describe '#action_icon' do
      it 'does not decorate action icon' do
        expect(status).to receive(:action_icon)

        subject.action_icon
      end
    end

    describe '#action_title' do
      it 'does not decorate action title' do
        expect(status).to receive(:action_title)

        subject.action_title
      end
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
    let(:build_status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }
    let(:status) { described_class.new(build_status) }

    it 'does override badge_tooltip' do
      expect(status.badge_tooltip).to eq('failed <br> (unknown failure)')
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }
    let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
    let(:build_status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }
    let(:status) { described_class.new(build_status) }

    it 'does override status_tooltip' do
      expect(status.status_tooltip).to eq 'failed <br> (unknown failure) (allowed to fail)'
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is failed' do
      context 'when build is allowed to fail' do
        let(:build) { create(:ci_build, :failed, :allowed_to_fail) }

        it 'is a correct match' do
          expect(subject).to be true
        end
      end

      context 'when build is not allowed to fail' do
        let(:build) { create(:ci_build, :failed) }

        it 'is not a correct match' do
          expect(subject).not_to be true
        end
      end
    end

    context 'when build did not fail' do
      context 'when build is allowed to fail' do
        let(:build) { create(:ci_build, :success, :allowed_to_fail) }

        it 'is not a correct match' do
          expect(subject).not_to be true
        end
      end

      context 'when build is not allowed to fail' do
        let(:build) { create(:ci_build, :success) }

        it 'is not a correct match' do
          expect(subject).not_to be true
        end
      end
    end
  end
end
