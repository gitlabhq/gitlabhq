# frozen_string_literal: true
require 'spec_helper'

describe Ci::ProcessBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { described_class.new(project, user).execute(build) }

  before do
    project.add_maintainer(user)
  end

  context 'when build is schedulable' do
    let(:build) { create(:ci_build, :created, :schedulable, user: user, project: project) }

    context 'when ci_enable_scheduled_build feature flag is enabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: true)
      end

      it 'schedules the build' do
        Timecop.freeze do
          expect(Ci::BuildScheduleWorker)
            .to receive(:perform_at).with(1.minute.since, build.id)

          subject

          expect(build).to be_scheduled
        end
      end
    end

    context 'when ci_enable_scheduled_build feature flag is disabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: false)
      end

      it 'enqueues the build' do
        subject

        expect(build).to be_manual
      end
    end
  end

  context 'when build is actionable' do
    let(:build) { create(:ci_build, :created, :actionable, user: user, project: project) }

    it 'actionizes the build' do
      subject

      expect(build).to be_manual
    end
  end

  context 'when build does not have any actions' do
    let(:build) { create(:ci_build, :created, user: user, project: project) }

    it 'enqueues the build' do
      subject

      expect(build).to be_pending
    end
  end
end
