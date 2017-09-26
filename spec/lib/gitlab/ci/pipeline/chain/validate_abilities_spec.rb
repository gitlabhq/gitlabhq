require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::ValidateAbilities do
  describe '#allowed_to_create?' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:ref) { 'master' }

    let(:pipeline) do
      build_stubbed(:ci_pipeline, ref: ref, project: project)
    end

    let(:command) do
      double('command', project: project, current_user: user)
    end

    subject do
      described_class.new(pipeline, command).allowed_to_create?
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_truthy }

      context 'when the branch is protected' do
        let!(:protected_branch) do
          create(:protected_branch, project: project, name: ref)
        end

        it { is_expected.to be_falsey }

        context 'when developers are allowed to merge' do
          let!(:protected_branch) do
            create(:protected_branch,
                   :developers_can_merge,
                   project: project,
                   name: ref)
          end

          it { is_expected.to be_truthy }
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
            create(:protected_tag,
                   :developers_can_create,
                   project: project,
                   name: ref)
          end

          it { is_expected.to be_truthy }
        end
      end
    end

    context 'when user is a master' do
      before do
        project.add_master(user)
      end

      it { is_expected.to be_truthy }

      context 'when the branch is protected' do
        let!(:protected_branch) do
          create(:protected_branch, project: project, name: ref)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the tag is protected' do
        let(:ref) { 'v1.0.0' }

        let!(:protected_tag) do
          create(:protected_tag, project: project, name: ref)
        end

        it { is_expected.to be_truthy }

        context 'when no one can create the tag' do
          let!(:protected_tag) do
            create(:protected_tag,
                   :no_one_can_create,
                   project: project,
                   name: ref)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when owner cannot create pipeline' do
      it { is_expected.to be_falsey }
    end
  end
end
