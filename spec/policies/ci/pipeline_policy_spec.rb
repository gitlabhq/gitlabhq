# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinePolicy, :models, :request_store, :use_clean_rails_redis_caching, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, developers: user) }
  let_it_be_with_reload(:pipeline) { create(:ci_empty_pipeline, project: project, created_at: 1.day.ago) }

  subject(:policy) do
    described_class.new(user, pipeline)
  end

  describe 'rules for protected ref' do
    context 'when no one can push or merge to the branch' do
      let_it_be(:protected_branch) do
        create(:protected_branch, :no_one_can_push, name: pipeline.ref, project: project)
      end

      it { is_expected.not_to be_allowed(:update_pipeline) }
      it { is_expected.not_to be_allowed(:cancel_pipeline) }
    end

    context 'when developers can push to the branch' do
      let_it_be(:protected_branch) do
        create(:protected_branch, :developers_can_merge, name: pipeline.ref, project: project)
      end

      it { is_expected.to be_allowed(:update_pipeline) }
      it { is_expected.to be_allowed(:cancel_pipeline) }
    end

    context 'when no one can create the tag' do
      let_it_be(:protected_tag) do
        create(:protected_tag, :no_one_can_create, name: pipeline.ref, project: project)
      end

      before do
        pipeline.update!(tag: true)
      end

      it { is_expected.not_to be_allowed(:update_pipeline) }
      it { is_expected.not_to be_allowed(:cancel_pipeline) }
    end

    context 'when no one can create the tag but it is not a tag' do
      let_it_be(:protected_tag) do
        create(:protected_tag, :no_one_can_create, name: pipeline.ref, project: project)
      end

      it { is_expected.to be_allowed(:update_pipeline) }
      it { is_expected.to be_allowed(:cancel_pipeline) }
    end
  end

  describe 'archived rules' do
    context 'when archive_builds_in is set' do
      before do
        stub_application_setting(archive_builds_in_seconds: 3600)
      end

      it { is_expected.not_to be_allowed(:update_pipeline) }
      it { is_expected.to be_allowed(:cancel_pipeline) }
    end

    context 'when archive_builds_in is not set' do
      before do
        stub_application_setting(archive_builds_in_seconds: nil)
      end

      it { is_expected.to be_allowed(:update_pipeline) }
      it { is_expected.to be_allowed(:cancel_pipeline) }
    end
  end

  context 'when maintainer is allowed to push to pipeline branch' do
    before_all do
      project.add_maintainer(user)

      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it { is_expected.to be_allowed(:update_pipeline) }
    it { is_expected.to be_allowed(:cancel_pipeline) }

    context 'and the pipeline is archived' do
      before do
        stub_application_setting(archive_builds_in_seconds: 3600)
      end

      it { is_expected.not_to be_allowed(:update_pipeline) }
      it { is_expected.to be_allowed(:cancel_pipeline) }
    end
  end

  context 'when user does not have access to internal CI' do
    before do
      project.project_feature.update!(builds_access_level: ProjectFeature::DISABLED)
    end

    it { is_expected.not_to be_allowed(:read_pipeline) }
  end

  describe 'destroy_pipeline' do
    context 'when user has owner access' do
      let_it_be(:user) { project.first_owner }

      it { is_expected.to be_allowed(:destroy_pipeline) }
    end

    context 'when user is not owner' do
      it { is_expected.not_to be_allowed(:destroy_pipeline) }
    end
  end

  describe 'read_pipeline_variable' do
    context 'when user has owner access' do
      let_it_be(:user) { project.first_owner }

      it { is_expected.to be_allowed(:read_pipeline_variable) }
    end

    context 'when user is developer and the creator of the pipeline' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project, user: user) }

      before do
        create(:protected_branch, :developers_can_merge, name: pipeline.ref, project: project)
      end

      it { is_expected.to be_allowed(:read_pipeline_variable) }
    end

    context 'when user is developer and it is not the creator of the pipeline' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project, user: project.first_owner) }

      before do
        create(:protected_branch, :developers_can_merge, name: pipeline.ref, project: project)
      end

      it { is_expected.not_to be_allowed(:read_pipeline_variable) }
    end

    context 'when user is not owner nor developer' do
      it { is_expected.not_to be_allowed(:read_pipeline_variable) }
    end
  end

  describe 'read_dependency' do
    before do
      allow(policy).to receive(:can?).with(:read_dependency, project).and_return(can_read_project_dependencies)
    end

    context 'when user is allowed to read project dependencies' do
      let(:can_read_project_dependencies) { true }

      it { is_expected.to be_allowed(:read_dependency) }
    end

    context 'when user is not allowed to read project dependencies' do
      let(:can_read_project_dependencies) { false }

      it { is_expected.not_to be_allowed(:read_dependency) }
    end
  end

  describe 'read_build' do
    before do
      allow(policy).to receive(:can?).with(:read_build, project).and_return(can_read_project_build)
    end

    context 'when user has read project build permission' do
      let(:can_read_project_build) { true }

      it { is_expected.to be_allowed(:read_build) }
    end

    context 'when the user does not have read project build permission' do
      let(:can_read_project_build) { false }

      it { is_expected.not_to be_allowed(:read_build) }

      context 'and the pipeline is external' do
        before do
          pipeline.update!(source: :external)
        end

        context 'and the user is a guest' do
          before_all do
            project.add_guest(user)
          end

          it { is_expected.not_to be_allowed(:read_build) }
        end

        context 'and the user is a reporter' do
          before_all do
            project.add_reporter(user)
          end

          it { is_expected.to be_allowed(:read_build) }
        end
      end
    end
  end

  describe 'read_pipeline_metadata' do
    let(:pipeline) { create(:ci_empty_pipeline, project: project) }

    context 'when user has read_pipeline ability' do
      let_it_be(:project) { create(:project, :private, :repository, guests: user) }

      it { is_expected.to be_allowed(:read_pipeline) }
      it { is_expected.to be_allowed(:read_pipeline_metadata) }
    end

    context 'when user does not have read_pipeline ability' do
      let_it_be(:project) { create(:project, :private, :repository) }

      it { is_expected.to be_disallowed(:read_pipeline) }
      it { is_expected.to be_disallowed(:read_pipeline_metadata) }
    end
  end
end
