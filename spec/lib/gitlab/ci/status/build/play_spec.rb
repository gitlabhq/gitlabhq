require 'spec_helper'

describe Gitlab::Ci::Status::Build::Play do
  let(:core_status) { double('core status') }
  let(:user) { double('user') }

  subject do
    described_class.new(core_status)
  end

  describe '#text' do
    it { expect(subject.text).to eq 'play' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'play' }
  end

  describe '#icon' do
    it 'does not override core status icon' do
      expect(core_status).to receive(:icon)

      subject.icon
    end
  end

  describe '.matches?' do
    context 'build is playable' do
      context 'when build stops an environment' do
        let(:build) do
          create(:ci_build, :playable, :teardown_environment)
        end

        it 'does not match' do
          expect(described_class.matches?(build, user))
            .to be false
        end
      end

      context 'when build does not stop an environment' do
        let(:build) { create(:ci_build, :playable) }

        it 'is a correct match' do
          expect(described_class.matches?(build, user))
            .to be true
        end
      end
    end

    context 'when build is not playable' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(described_class.matches?(build, user))
          .to be false
      end
    end
  end
end
