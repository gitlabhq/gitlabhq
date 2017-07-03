require 'spec_helper'

describe Ci::PipelinePolicy, :models do
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policies) do
    described_class.abilities(user, pipeline).to_set
  end

  describe 'rules' do
    describe 'rules for protected branch' do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)

        create(:protected_branch, branch_policy,
               name: pipeline.ref, project: project)
      end

      context 'when no one can push or merge to the branch' do
        let(:branch_policy) { :no_one_can_push }

        it 'does not include ability to update pipeline' do
          expect(policies).to be_disallowed :update_pipeline
        end
      end

      context 'when developers can push to the branch' do
        let(:branch_policy) { :developers_can_push }

        it 'includes ability to update pipeline' do
          expect(policies).to be_allowed :update_pipeline
        end
      end

      context 'when developers can push to the branch' do
        let(:branch_policy) { :developers_can_merge }

        it 'includes ability to update pipeline' do
          expect(policies).to be_allowed :update_pipeline
        end
      end
    end
  end
end
