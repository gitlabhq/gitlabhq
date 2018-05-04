require 'spec_helper'

describe DeployTokenPolicy do
  let(:current_user) { create(:user) }
  let(:project) { create(:project) }
  let(:deploy_token) { create(:deploy_token, projects: [project]) }

  subject { described_class.new(current_user, deploy_token) }

  describe 'creating a deploy key' do
    context 'when user is master' do
      before do
        project.add_master(current_user)
      end

      it { is_expected.to be_allowed(:create_deploy_token) }
    end

    context 'when user is not master' do
      before do
        project.add_developer(current_user)
      end

      it { is_expected.to be_disallowed(:create_deploy_token) }
    end
  end

  describe 'updating a deploy key' do
    context 'when user is master' do
      before do
        project.add_master(current_user)
      end

      it { is_expected.to be_allowed(:update_deploy_token) }
    end

    context 'when user is not master' do
      before do
        project.add_developer(current_user)
      end

      it { is_expected.to be_disallowed(:update_deploy_token) }
    end
  end
end
