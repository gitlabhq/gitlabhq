require 'spec_helper'

describe Gitlab::Ci::Status::Build::Action do
  let(:status) { double('core status') }
  let(:user) { double('user') }

  subject do
    described_class.new(status)
  end

  describe '#label' do
    before do
      allow(status).to receive(:label).and_return('label')
    end

    context 'when status has action' do
      before do
        allow(status).to receive(:has_action?).and_return(true)
      end

      it 'does not append text' do
        expect(subject.label).to eq 'label'
      end
    end

    context 'when status does not have action' do
      before do
        allow(status).to receive(:has_action?).and_return(false)
      end

      it 'appends text about action not allowed' do
        expect(subject.label).to eq 'label (not allowed)'
      end
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is playable action' do
      let(:build) { create(:ci_build, :playable) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not playable action' do
      let(:build) { create(:ci_build, :non_playable) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end

  describe '#badge_tooltip' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :non_playable) }
    let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'returns the status' do
      expect(subject.badge_tooltip).to eq('created')
    end
  end
end
