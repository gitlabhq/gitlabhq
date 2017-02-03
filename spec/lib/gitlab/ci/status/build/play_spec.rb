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

  describe '#group' do
    it { expect(subject.group).to eq 'manual' }
  end

  describe 'action details' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build) }
    let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

    describe '#has_action?' do
      context 'when user is allowed to update build' do
        before { build.project.team << [user, :developer] }

        it { is_expected.to have_action }
      end

      context 'when user is not allowed to update build' do
        it { is_expected.not_to have_action }
      end
    end

    describe '#action_path' do
      it { expect(subject.action_path).to include "#{build.id}/play" }
    end

    describe '#action_icon' do
      it { expect(subject.action_icon).to eq 'icon_action_play' }
    end

    describe '#action_title' do
      it { expect(subject.action_title).to eq 'Play' }
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is playable' do
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
