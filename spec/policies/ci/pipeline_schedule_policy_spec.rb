# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulePolicy, :models do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline_schedule, reload: true) { create(:ci_pipeline_schedule, :nightly, project: project) }

  let(:policy) do
    described_class.new(user, pipeline_schedule)
  end

  describe 'rules' do
    describe 'rules for protected ref' do
      before do
        project.add_developer(user)
      end

      context 'when no one can push or merge to the branch' do
        before do
          create(:protected_branch, :no_one_can_push,
                 name: pipeline_schedule.ref, project: project)
        end

        it 'does not include ability to play pipeline schedule' do
          expect(policy).to be_disallowed :play_pipeline_schedule
        end
      end

      context 'when developers can push to the branch' do
        before do
          create(:protected_branch, :developers_can_merge,
                 name: pipeline_schedule.ref, project: project)
        end

        it 'includes ability to update pipeline' do
          expect(policy).to be_allowed :play_pipeline_schedule
        end
      end

      context 'when no one can create the tag' do
        let(:tag) { 'v1.0.0' }

        before do
          pipeline_schedule.update!(ref: tag)

          create(:protected_tag, :no_one_can_create,
                 name: pipeline_schedule.ref, project: project)
        end

        it 'does not include ability to play pipeline schedule' do
          expect(policy).to be_disallowed :play_pipeline_schedule
        end
      end

      context 'when no one can create the tag but it is not a tag' do
        before do
          create(:protected_tag, :no_one_can_create,
                 name: pipeline_schedule.ref, project: project)
        end

        it 'includes ability to play pipeline schedule' do
          expect(policy).to be_allowed :play_pipeline_schedule
        end
      end
    end

    describe 'rules for owner of schedule' do
      before do
        project.add_developer(user)
        pipeline_schedule.update!(owner: user)
      end

      it 'includes abilities to do all operations on pipeline schedule' do
        expect(policy).to be_allowed :play_pipeline_schedule
        expect(policy).to be_allowed :update_pipeline_schedule
        expect(policy).to be_allowed :admin_pipeline_schedule
      end
    end

    describe 'rules for a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'includes abilities to do all operations on pipeline schedule' do
        expect(policy).to be_allowed :play_pipeline_schedule
        expect(policy).to be_allowed :update_pipeline_schedule
        expect(policy).to be_allowed :admin_pipeline_schedule
      end
    end

    describe 'rules for non-owner of schedule' do
      let(:owner) { create(:user) }

      before do
        project.add_maintainer(owner)
        project.add_maintainer(user)
        pipeline_schedule.update!(owner: owner)
      end

      it 'includes abilities to take ownership' do
        expect(policy).to be_allowed :take_ownership_pipeline_schedule
      end
    end
  end
end
