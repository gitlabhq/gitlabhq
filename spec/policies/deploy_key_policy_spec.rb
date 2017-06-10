require 'spec_helper'

describe DeployKeyPolicy, models: true do
  subject { described_class.abilities(current_user, deploy_key).to_set }

  describe 'updating a deploy_key' do
    context 'when a regular user' do
      let(:current_user) { create(:user) }

      context 'tries to update private deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: false) }
        let(:project) { create(:project_empty_repo) }

        before do
          project.add_master(current_user)
          project.deploy_keys << deploy_key
        end

        it { is_expected.to include(:update_deploy_key) }
      end

      context 'tries to update private deploy key attached to other project' do
        let(:deploy_key) { create(:deploy_key, public: false) }
        let(:other_project) { create(:project_empty_repo) }

        before do
          other_project.deploy_keys << deploy_key
        end

        it { is_expected.not_to include(:update_deploy_key) }
      end

      context 'tries to update public deploy key' do
        let(:deploy_key) { create(:another_deploy_key, public: true) }

        it { is_expected.not_to include(:update_deploy_key) }
      end
    end

    context 'when an admin user' do
      let(:current_user) { create(:user, :admin) }

      context ' tries to update private deploy key' do
        let(:deploy_key) { create(:deploy_key, public: false) }

        it { is_expected.to include(:update_deploy_key) }
      end

      context 'when an admin user tries to update public deploy key' do
        let(:deploy_key) { create(:another_deploy_key, public: true) }

        it { is_expected.to include(:update_deploy_key) }
      end
    end
  end
end
