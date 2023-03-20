# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildScheduleWorker, feature_category: :continuous_integration do
  subject { described_class.new.perform(build.id) }

  context 'when build is found' do
    context 'when build is scheduled' do
      let(:build) { create(:ci_build, :scheduled) }

      it 'executes RunScheduledBuildService' do
        expect_any_instance_of(Ci::RunScheduledBuildService)
          .to receive(:execute).once

        subject
      end
    end

    context 'when build is not scheduled' do
      let(:build) { create(:ci_build, :created) }

      it 'executes RunScheduledBuildService' do
        expect_any_instance_of(Ci::RunScheduledBuildService)
          .not_to receive(:execute)

        subject
      end
    end
  end

  context 'when build is not found' do
    let(:build) { build_stubbed(:ci_build, :scheduled) }

    it 'does nothing' do
      expect_any_instance_of(Ci::RunScheduledBuildService)
        .not_to receive(:execute)

      subject
    end
  end
end
