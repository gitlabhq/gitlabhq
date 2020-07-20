# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::ProcessBuildService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { described_class.new(project, user).execute(build, current_status) }

  before do
    project.add_maintainer(user)
  end

  context 'when build has on_success option' do
    let(:build) { create(:ci_build, :created, when: :on_success, user: user, project: project) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end

    context 'when current status is skipped' do
      let(:current_status) { 'skipped' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end

    context 'when current status is failed' do
      let(:current_status) { 'failed' }

      it 'does not change the build status' do
        expect { subject }.to change { build.status }.to('skipped')
      end
    end
  end

  context 'when build has on_failure option' do
    let(:build) { create(:ci_build, :created, when: :on_failure, user: user, project: project) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('skipped')
      end
    end

    context 'when current status is failed' do
      let(:current_status) { 'failed' }

      it 'does not change the build status' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end
  end

  context 'when build has always option' do
    let(:build) { create(:ci_build, :created, when: :always, user: user, project: project) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end

    context 'when current status is failed' do
      let(:current_status) { 'failed' }

      it 'does not change the build status' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end
  end

  context 'when build has manual option' do
    let(:build) { create(:ci_build, :created, :actionable, user: user, project: project) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('manual')
      end
    end

    context 'when current status is failed' do
      let(:current_status) { 'failed' }

      it 'does not change the build status' do
        expect { subject }.to change { build.status }.to('skipped')
      end
    end
  end

  context 'when build has delayed option' do
    before do
      allow(Ci::BuildScheduleWorker).to receive(:perform_at) { }
    end

    let(:build) { create(:ci_build, :created, :schedulable, user: user, project: project) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'changes the build status' do
        expect { subject }.to change { build.status }.to('scheduled')
      end
    end

    context 'when current status is failed' do
      let(:current_status) { 'failed' }

      it 'does not change the build status' do
        expect { subject }.to change { build.status }.to('skipped')
      end
    end
  end

  context 'when build is scheduled with DAG' do
    let(:pipeline) { create(:ci_pipeline, ref: 'master', project: project) }
    let!(:build) { create(:ci_build, :created, when: :on_success, pipeline: pipeline, scheduling_type: :dag) }
    let!(:other_build) { create(:ci_build, :created, when: :on_success, pipeline: pipeline) }
    let!(:build_on_other_build) { create(:ci_build_need, build: build, name: other_build.name) }

    context 'when current status is success' do
      let(:current_status) { 'success' }

      it 'enqueues the build' do
        expect { subject }.to change { build.status }.to('pending')
      end
    end

    context 'when current status is skipped' do
      let(:current_status) { 'skipped' }

      it 'skips the build' do
        expect { subject }.to change { build.status }.to('skipped')
      end
    end
  end
end
