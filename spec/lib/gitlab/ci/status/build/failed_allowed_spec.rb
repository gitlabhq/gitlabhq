# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::FailedAllowed, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:user) { instance_double(User) }
  let(:build) { create(:ci_build, :failed, :allowed_to_fail, project: project) }
  let(:core_status) { double('core status') }

  subject(:status) { described_class.new(core_status) }

  describe '#text' do
    it 'does not override status text' do
      expect(core_status).to receive(:text)

      status.text
    end
  end

  describe '#icon' do
    it 'returns a warning icon' do
      expect(status.icon).to eq 'status_warning'
    end
  end

  describe '#label' do
    it 'returns information about failed but allowed to fail status' do
      expect(status.label).to eq 'failed (allowed to fail)'
    end
  end

  describe '#group' do
    it 'returns status failed with warnings status group' do
      expect(status.group).to eq 'failed-with-warnings'
    end
  end

  describe 'action details' do
    describe '#has_action?' do
      it 'does not decorate action details' do
        expect(core_status).to receive(:has_action?)

        status.has_action?
      end
    end

    describe '#action_path' do
      it 'does not decorate action path' do
        expect(core_status).to receive(:action_path)

        status.action_path
      end
    end

    describe '#action_icon' do
      it 'does not decorate action icon' do
        expect(core_status).to receive(:action_icon)

        status.action_icon
      end
    end

    describe '#action_title' do
      it 'does not decorate action title' do
        expect(core_status).to receive(:action_title)

        status.action_title
      end
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
    let(:build_status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }
    let(:status) { described_class.new(build_status) }

    it 'does override badge_tooltip' do
      expect(status.badge_tooltip).to eq('Failed - (unknown failure)')
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }
    let(:failed_status) { Gitlab::Ci::Status::Failed.new(build, user) }
    let(:build_status) { Gitlab::Ci::Status::Build::Failed.new(failed_status) }
    let(:status) { described_class.new(build_status) }

    it 'does override status_tooltip' do
      expect(status.status_tooltip).to eq 'Failed - (unknown failure) (allowed to fail)'
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is failed' do
      context 'when build is allowed to fail' do
        let(:build) { create(:ci_build, :failed, :allowed_to_fail, project: project) }

        it 'is a correct match' do
          is_expected.to be true
        end
      end

      context 'when build is not allowed to fail' do
        let(:build) { create(:ci_build, :failed, project: project) }

        it 'is not a correct match' do
          is_expected.to be false
        end
      end
    end

    context 'when build did not fail' do
      context 'when build is allowed to fail' do
        let(:build) { create(:ci_build, :success, :allowed_to_fail, project: project) }

        it 'is not a correct match' do
          is_expected.to be false
        end
      end

      context 'when build is not allowed to fail' do
        let(:build) { create(:ci_build, :success, project: project) }

        it 'is not a correct match' do
          is_expected.to be false
        end
      end
    end
  end
end
