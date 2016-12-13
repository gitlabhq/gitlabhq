require 'spec_helper'

describe Gitlab::Ci::Status::Build::Play do
  let(:status) { double('core') }
  let(:user) { double('user') }

  subject { described_class.new(status) }

  describe '#text' do
    it { expect(subject.text).to eq 'manual' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'manual play action' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_manual' }
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'build is playable' do
      context 'when build stops an environment' do
        let(:build) do
          create(:ci_build, :playable, :teardown_environment)
        end

        it 'does not match' do
          expect(subject).to be false
        end
      end

      context 'when build does not stop an environment' do
        let(:build) { create(:ci_build, :playable) }

        it 'is a correct match' do
          expect(subject).to be true
        end
      end
    end

    context 'when build is not playable' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
