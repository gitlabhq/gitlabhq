require 'spec_helper'

describe Gitlab::Ci::Status::Build::Failed do
  let(:build) { create(:ci_build, :script_failure) }
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
    it 'does not override label' do
      expect(status).to receive(:label)

      subject.label
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:status) { Gitlab::Ci::Status::Failed.new(build, user) }

    it 'does override badge_tooltip' do
      expect(subject.badge_tooltip).to eq 'failed <br> (script failure)'
    end
  end

  describe '#status_tooltip' do
    let(:user) { create(:user) }
    let(:status) { Gitlab::Ci::Status::Failed.new(build, user) }

    it 'does override status_tooltip' do
      expect(subject.status_tooltip).to eq 'failed <br> (script failure)'
    end
  end

  describe '.matches?' do
    context 'with a failed build' do
      it 'returns true' do
        expect(described_class.matches?(build, user)).to be_truthy
      end
    end

    context 'with any other type of build' do
      let(:build) { create(:ci_build, :success) }

      it 'returns false' do
        expect(described_class.matches?(build, user)).to be_falsy
      end
    end
  end
end
