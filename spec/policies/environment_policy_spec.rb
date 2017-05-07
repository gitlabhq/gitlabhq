require 'spec_helper'

describe EnvironmentPolicy do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:environment) do
    create(:environment, :with_review_app, project: project)
  end

  let(:policies) do
    described_class.abilities(user, environment).to_set
  end

  describe '#rules' do
    context 'when user does not have access to the project' do
      let(:project) { create(:project, :private) }

      it 'does not include ability to stop environment' do
        expect(policies).not_to include :stop_environment
      end
    end

    context 'when anonymous user has access to the project' do
      let(:project) { create(:project, :public) }

      it 'does not include ability to stop environment' do
        expect(policies).not_to include :stop_environment
      end
    end

    context 'when team member has access to the project' do
      let(:project) { create(:project, :public) }

      before do
        project.add_master(user)
      end

      context 'when team member has ability to stop environment' do
        it 'does includes ability to stop environment' do
          expect(policies).to include :stop_environment
        end
      end

      context 'when team member has no ability to stop environment' do
        before do
          create(:protected_branch, :no_one_can_push,
                 name: 'master', project: project)
        end

        it 'does not include ability to stop environment' do
          expect(policies).not_to include :stop_environment
        end
      end
    end
  end
end
