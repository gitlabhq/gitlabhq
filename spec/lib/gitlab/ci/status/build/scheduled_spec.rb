# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Scheduled do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :stubbed_repository) }

  let(:build) { create(:ci_build, :scheduled, project: project) }
  let(:status) { Gitlab::Ci::Status::Core.new(build, user) }

  subject { described_class.new(status) }

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '#status_tooltip' do
    let(:build) { create(:ci_build, scheduled_at: 1.minute.since, project: project) }

    it 'has a placeholder for the remaining time' do
      expect(subject.status_tooltip).to include('%{remainingTime}')
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

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
