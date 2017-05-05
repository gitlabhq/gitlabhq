require 'spec_helper'

describe Ci::BuildPolicy, :models do
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policies) do
    described_class.abilities(user, build).to_set
  end

  shared_context 'public pipelines disabled' do
    before { project.update_attribute(:public_builds, false) }
  end

  describe '#rules' do
    context 'when user does not have access to the project' do
      let(:project) { create(:empty_project, :private) }

      context 'when public builds are enabled' do
        it 'does not include ability to read build' do
          expect(policies).not_to include :read_build
        end
      end

      context 'when public builds are disabled' do
        include_context 'public pipelines disabled'

        it 'does not include ability to read build' do
          expect(policies).not_to include :read_build
        end
      end
    end

    context 'when anonymous user has access to the project' do
      let(:project) { create(:empty_project, :public) }

      context 'when public builds are enabled' do
        it 'includes ability to read build' do
          expect(policies).to include :read_build
        end
      end

      context 'when public builds are disabled' do
        include_context 'public pipelines disabled'

        it 'does not include ability to read build' do
          expect(policies).not_to include :read_build
        end
      end
    end

    context 'when team member has access to the project' do
      let(:project) { create(:empty_project, :public) }

      context 'team member is a guest' do
        before { project.team << [user, :guest] }

        context 'when public builds are enabled' do
          it 'includes ability to read build' do
            expect(policies).to include :read_build
          end
        end

        context 'when public builds are disabled' do
          include_context 'public pipelines disabled'

          it 'does not include ability to read build' do
            expect(policies).not_to include :read_build
          end
        end
      end

      context 'team member is a reporter' do
        before { project.team << [user, :reporter] }

        context 'when public builds are enabled' do
          it 'includes ability to read build' do
            expect(policies).to include :read_build
          end
        end

        context 'when public builds are disabled' do
          include_context 'public pipelines disabled'

          it 'does not include ability to read build' do
            expect(policies).to include :read_build
          end
        end
      end
    end

    describe 'rules for manual actions' do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
      end

      context 'when branch build is assigned to is protected' do
        before do
          create(:protected_branch, :no_one_can_push,
                 name: 'some-ref', project: project)
        end

        context 'when build is a manual action' do
          let(:build) do
            create(:ci_build, :manual, ref: 'some-ref', pipeline: pipeline)
          end

          it 'does not include ability to update build' do
            expect(policies).not_to include :update_build
          end
        end

        context 'when build is not a manual action' do
          let(:build) do
            create(:ci_build, ref: 'some-ref', pipeline: pipeline)
          end

          it 'includes ability to update build' do
            expect(policies).to include :update_build
          end
        end
      end

      context 'when branch build is assigned to is not protected' do
        context 'when build is a manual action' do
          let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

          it 'includes ability to update build' do
            expect(policies).to include :update_build
          end
        end

        context 'when build is not a manual action' do
          let(:build) { create(:ci_build, pipeline: pipeline) }

          it 'includes ability to update build' do
            expect(policies).to include :update_build
          end
        end
      end
    end
  end
end
