# frozen_string_literal: true

require 'spec_helper'

describe Ci::RunScheduledBuildService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new(project, user).execute(build) }

  context 'when user can update build' do
    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: pipeline.ref, project: project)
    end

    context 'when build is scheduled' do
      context 'when scheduled_at is expired' do
        let(:build) { create(:ci_build, :expired_scheduled, user: user, project: project, pipeline: pipeline) }

        it 'can run the build' do
          expect { subject }.not_to raise_error

          expect(build).to be_pending
        end
      end

      context 'when scheduled_at is not expired' do
        let(:build) { create(:ci_build, :scheduled, user: user, project: project, pipeline: pipeline) }

        it 'can not run the build' do
          expect { subject }.to raise_error(StateMachines::InvalidTransition)

          expect(build).to be_scheduled
        end
      end
    end

    context 'when build is not scheduled' do
      let(:build) { create(:ci_build, :created, user: user, project: project, pipeline: pipeline) }

      it 'can not run the build' do
        expect { subject }.to raise_error(StateMachines::InvalidTransition)

        expect(build).to be_created
      end
    end
  end

  context 'when user can not update build' do
    context 'when build is scheduled' do
      let(:build) { create(:ci_build, :scheduled, user: user, project: project, pipeline: pipeline) }

      it 'can not run the build' do
        expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)

        expect(build).to be_scheduled
      end
    end
  end
end
