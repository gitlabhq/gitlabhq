# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Failed, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:build) { create(:ci_build, :script_failure, project: project) }
  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }
  let(:user) { build_stubbed(:user) }

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
    it 'does not override label' do
      expect(status).to receive(:label)

      status.label
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:core_status) { Gitlab::Ci::Status::Failed.new(build, user) }

    it 'does override badge_tooltip' do
      expect(status.badge_tooltip).to eq 'Failed - (script failure)'
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }
    let(:core_status) { Gitlab::Ci::Status::Failed.new(build, user) }

    it 'does override status_tooltip' do
      expect(status.status_tooltip).to eq 'Failed - (script failure)'
    end
  end

  describe '.matches?' do
    context 'with a failed build' do
      it 'returns true' do
        expect(described_class.matches?(build, user)).to be true
      end
    end

    context 'with any other type of build' do
      let(:build) { create(:ci_build, :success, project: project) }

      it 'returns false' do
        expect(described_class.matches?(build, user)).to be false
      end
    end
  end

  describe 'covers all failure reasons' do
    let(:core_status) { Gitlab::Ci::Status::Failed.new(build, user) }
    let(:tooltip) { status.status_tooltip }

    CommitStatus.failure_reasons.keys.each do |failure_reason|
      context failure_reason do
        before do
          build.failure_reason = failure_reason
        end

        it "is a valid status" do
          expect { tooltip }.not_to raise_error
        end
      end
    end

    context 'invalid failure message' do
      before do
        expect(build).to receive(:failure_reason) { 'invalid failure message' }
      end

      it "is an invalid status" do
        expect { tooltip }.to raise_error(/key not found:/)
      end
    end
  end
end
