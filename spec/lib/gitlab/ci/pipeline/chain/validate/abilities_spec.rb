# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::Abilities, feature_category: :continuous_integration do
  include ProjectForksHelper
  let(:project) { create(:project, :test_repo) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build_stubbed(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: origin_ref,
      merge_request: merge_request,
      trigger_request: trigger_request)
  end

  let(:step) { described_class.new(pipeline, command) }

  let(:ref) { 'master' }
  let(:origin_ref) { ref }
  let(:merge_request) { nil }
  let(:trigger_request) { nil }

  shared_context 'detached merge request pipeline' do
    let(:merge_request) do
      create(:merge_request,
        source_project: project,
        source_branch: ref,
        target_project: project,
        target_branch: 'feature')
    end

    let(:pipeline) do
      build(:ci_pipeline,
        source: :merge_request_event,
        merge_request: merge_request,
        project: project)
    end

    let(:origin_ref) { merge_request.ref_path }
  end

  context 'when users has no ability to run a pipeline' do
    before do
      step.perform!
    end

    it 'adds an error about insufficient permissions' do
      expect(pipeline.errors.to_a)
        .to include(/Insufficient permissions/)
    end

    it 'breaks the pipeline builder chain' do
      expect(step.break?).to eq true
    end
  end

  context 'when user has ability to create a pipeline' do
    before do
      project.add_developer(user)

      step.perform!
    end

    it 'does not invalidate the pipeline' do
      expect(pipeline).to be_valid
    end

    it 'does not break the chain' do
      expect(step.break?).to eq false
    end

    context 'when project is deleted' do
      before do
        project.update!(pending_delete: true)
      end

      specify { expect(step.perform!).to contain_exactly('Project is deleted!') }
    end

    context 'with project imports in progress' do
      let(:project) { create(:project, :import_started, import_type: 'gitlab_project') }

      before do
        step.perform!
      end

      it 'adds an error about imports' do
        expect(pipeline.errors.to_a)
          .to include(/before project import is complete/)
      end

      it 'breaks the pipeline builder chain' do
        expect(step.break?).to eq true
      end
    end

    context 'with completed project imports' do
      let(:project) { create(:project, :import_finished, import_type: 'gitlab_project') }

      before do
        step.perform!
      end

      it 'does not invalidate the pipeline' do
        expect(pipeline).to be_valid
      end

      it 'does not break the chain' do
        expect(step.break?).to eq false
      end
    end
  end

  describe '#allowed_to_write_ref?' do
    subject { step.send(:allowed_to_write_ref?) }

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_truthy }

      context 'when pipeline is a detached merge request pipeline' do
        include_context 'detached merge request pipeline'

        it { is_expected.to be_truthy }
      end

      context 'when the branch is protected' do
        let!(:protected_branch) do
          create(:protected_branch, project: project, name: ref)
        end

        it { is_expected.to be_falsey }

        context 'when pipeline is a detached merge request pipeline' do
          include_context 'detached merge request pipeline'

          it { is_expected.to be_falsey }
        end

        context 'when developers are allowed to merge' do
          let!(:protected_branch) do
            create(:protected_branch, :developers_can_merge, project: project, name: ref)
          end

          it { is_expected.to be_truthy }

          context 'when pipeline is a detached merge request pipeline' do
            include_context 'detached merge request pipeline'

            it { is_expected.to be_truthy }
          end
        end
      end

      context 'when the tag is protected' do
        let(:ref) { 'v1.0.0' }

        let!(:protected_tag) do
          create(:protected_tag, project: project, name: ref)
        end

        it { is_expected.to be_falsey }

        context 'when developers are allowed to create the tag' do
          let!(:protected_tag) do
            create(:protected_tag, :developers_can_create, project: project, name: ref)
          end

          it { is_expected.to be_truthy }
        end
      end
    end

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_truthy }

      context 'when the branch is protected' do
        let!(:protected_branch) do
          create(:protected_branch, project: project, name: ref)
        end

        it { is_expected.to be_truthy }

        context 'when pipeline is a detached merge request pipeline' do
          include_context 'detached merge request pipeline'

          it { is_expected.to be_truthy }
        end
      end

      context 'when the tag is protected' do
        let(:ref) { 'v1.0.0' }

        let!(:protected_tag) do
          create(:protected_tag, project: project, name: ref)
        end

        it { is_expected.to be_truthy }

        context 'when no one can create the tag' do
          let!(:protected_tag) do
            create(:protected_tag, :no_one_can_create, project: project, name: ref)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when owner cannot create pipeline' do
      it { is_expected.to be_falsey }
    end

    context 'when a merge request comes from a fork' do
      let(:author) { create(:user) }
      let(:fork_user) { create(:user) }
      let(:target_project) { create(:project, :test_repo, :public) }
      let(:source_project) { fork_project(target_project, fork_user, repository: true) }
      let(:merge_request) do
        create(:merge_request, source_project: source_project, target_project: target_project)
      end

      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: pipeline_project,
          current_user: author,
          merge_request: merge_request
        )
      end

      before do
        source_project.add_developer(author)
      end

      context 'and the author is a member of the target project' do
        let(:pipeline_project) { target_project }

        before do
          target_project.add_developer(author)
          allow(command).to receive(:origin_ref).and_return('refs/merge-requests/1/head')
        end

        it { is_expected.to be_truthy }
      end

      context 'and the author is not a member of the target project' do
        let(:pipeline_project) { source_project }

        before do
          allow(command).to receive(:origin_ref).and_return('feature')
          source_project.repository.create_branch('feature', source_project.default_branch)
        end

        context 'when there is no branch protection rule matching the MR source ref' do
          it { is_expected.to be_truthy }
        end

        context 'when a branch protection rule matches the MR source ref' do
          let!(:protected_branch) do
            create(:protected_branch, project: source_project, name: 'feature')
          end

          it { is_expected.to be_falsey }

          context 'when the author is a maintainer of the source project' do
            before do
              source_project.add_maintainer(author)
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end
  end
end
