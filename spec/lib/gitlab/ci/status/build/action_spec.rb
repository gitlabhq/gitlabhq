# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Action, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }

  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }
  let(:user) { instance_double(User) }

  subject(:status) { described_class.new(core_status) }

  describe '#label' do
    before do
      allow(core_status).to receive(:label).and_return('label')
    end

    context 'when status has action' do
      before do
        allow(core_status).to receive(:has_action?).and_return(true)
      end

      it 'does not append text' do
        expect(status.label).to eq 'label'
      end
    end

    context 'when status does not have action' do
      before do
        allow(core_status).to receive(:has_action?).and_return(false)
      end

      it 'appends text about action not allowed' do
        expect(status.label).to eq 'label (not allowed)'
      end
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is playable action' do
      let(:build) { create(:ci_build, :playable, project: project) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not playable action' do
      let(:build) { create(:ci_build, :non_playable, project: project) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end

  describe '#badge_tooltip' do
    let_it_be(:user, freeze: true) { create(:user) }

    let(:build) { create(:ci_build, :non_playable, project: project) }
    let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

    it 'returns the status' do
      expect(status.badge_tooltip).to eq('created')
    end
  end
end
