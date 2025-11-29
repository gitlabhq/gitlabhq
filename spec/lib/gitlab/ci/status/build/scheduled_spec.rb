# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Scheduled, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project, :stubbed_repository) }
  let_it_be(:user, freeze: true) { create(:user) }

  let(:build) { create(:ci_build, :scheduled, project: project) }
  let(:core_status) { Gitlab::Ci::Status::Core.new(build, user) }

  subject(:status) { described_class.new(core_status) }

  describe '#illustration' do
    it { expect(status.illustration).to include(:image, :size, :title) }
  end

  describe '#status_tooltip' do
    let(:build) { create(:ci_build, scheduled_at: 1.minute.since, project: project) }

    it 'has a placeholder for the remaining time' do
      expect(status.status_tooltip).to include('%{remainingTime}')
    end
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is scheduled and scheduled_at is present' do
      let(:build) { create(:ci_build, :expired_scheduled, project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when build is scheduled' do
      let(:build) { create(:ci_build, status: :scheduled, project: project) }

      it { is_expected.to be_falsy }
    end

    context 'when scheduled_at is present' do
      let(:build) { create(:ci_build, scheduled_at: 1.minute.since, project: project) }

      it { is_expected.to be_falsy }
    end
  end
end
