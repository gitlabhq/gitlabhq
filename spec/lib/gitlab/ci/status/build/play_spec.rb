require 'spec_helper'

describe Gitlab::Ci::Status::Build::Play do
  let(:user) { create(:user) }
  let(:project) { build.project }
  let(:build) { create(:ci_build, :manual) }
  let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

  subject { described_class.new(status) }

  describe '#label' do
    it 'has a label that says it is a manual action' do
      expect(subject.label).to eq 'manual play action'
    end
  end

  describe '#status_tooltip' do
    it 'does not override status status_tooltip' do
      expect(status).to receive(:status_tooltip)

      subject.status_tooltip
    end
  end

  describe '#badge_tooltip' do
    it 'does not override status badge_tooltip' do
      expect(status).to receive(:badge_tooltip)

      subject.badge_tooltip
    end
  end

  describe '#has_action?' do
    context 'when user is allowed to update build' do
      context 'when user is allowed to trigger protected action' do
        before do
          project.add_developer(user)

          create(:protected_branch, :developers_can_merge,
                 name: build.ref, project: project)
        end

        it { is_expected.to have_action }
      end

      context 'when user can not push to the branch' do
        before do
          build.project.add_developer(user)
        end

        it { is_expected.not_to have_action }
      end
    end

    context 'when user is not allowed to update build' do
      it { is_expected.not_to have_action }
    end
  end

  describe '#action_path' do
    it { expect(subject.action_path).to include "#{build.id}/play" }
  end

  describe '#action_icon' do
    it { expect(subject.action_icon).to eq 'play' }
  end

  describe '#action_title' do
    it { expect(subject.action_title).to eq 'Play' }
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
