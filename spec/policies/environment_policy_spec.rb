require 'spec_helper'

describe EnvironmentPolicy do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:environment) do
    create(:environment, :with_review_app, project: project)
  end

  let(:policy) do
    described_class.new(user, environment)
  end

  describe '#rules' do
    context 'when user does not have access to the project' do
      let(:project) { create(:project, :private, :repository) }

      it 'does not include ability to stop environment' do
        expect(policy).to be_disallowed :stop_environment
      end
    end

    context 'when anonymous user has access to the project' do
      let(:project) { create(:project, :public, :repository) }

      it 'does not include ability to stop environment' do
        expect(policy).to be_disallowed :stop_environment
      end
    end

    context 'when team member has access to the project' do
      let(:project) { create(:project, :public, :repository) }

      before do
        project.add_developer(user)
      end

      context 'when team member has ability to stop environment' do
        it 'does includes ability to stop environment' do
          expect(policy).to be_allowed :stop_environment
        end
      end

      context 'when team member has no ability to stop environment' do
        before do
          create(:protected_branch, :no_one_can_push,
                 name: 'master', project: project)
        end

        it 'does not include ability to stop environment' do
          expect(policy).to be_disallowed :stop_environment
        end
      end
    end
  end
end
