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
    using RSpec::Parameterized::TableSyntax

    let(:pipeline) { create(:ci_pipeline, ref: 'master', project: project) }
    let!(:build) { create(:ci_build, :created, when: build_when, pipeline: pipeline, scheduling_type: :dag) }
    let!(:other_build) { create(:ci_build, :created, when: :on_success, pipeline: pipeline) }
    let!(:build_on_other_build) { create(:ci_build_need, build: build, name: other_build.name) }

    where(:build_when, :current_status, :after_status) do
      :on_success | 'success' | 'pending'
      :on_success | 'skipped' | 'skipped'
      :manual     | 'success' | 'manual'
      :manual     | 'skipped' | 'skipped'
      :delayed    | 'success' | 'manual'
      :delayed    | 'skipped' | 'skipped'
    end

    with_them do
      it 'proceeds the build' do
        expect { subject }.to change { build.status }.to(after_status)
      end
    end
  end
end
