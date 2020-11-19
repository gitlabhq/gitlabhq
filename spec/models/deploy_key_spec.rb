# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKey, :mailer do
  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:projects) }
    it { is_expected.to have_many(:protected_branch_push_access_levels) }
  end

  describe 'notification' do
    let(:user) { create(:user) }

    it 'does not send a notification' do
      perform_enqueued_jobs do
        create(:deploy_key, user: user)
      end

      should_not_email(user)
    end
  end

  describe '#user' do
    let(:deploy_key) { create(:deploy_key) }
    let(:user) { create(:user) }

    context 'when user is set' do
      before do
        deploy_key.user = user
      end

      it 'returns the user' do
        expect(deploy_key.user).to be(user)
      end
    end

    context 'when user is not set' do
      it 'returns the ghost user' do
        expect(deploy_key.user).to eq(User.ghost)
      end
    end
  end

  describe '.with_write_access_for_project' do
    let_it_be(:project) { create(:project, :private) }

    subject { described_class.with_write_access_for_project(project) }

    context 'when no project is passed in' do
      let(:project) { nil }

      it { is_expected.to be_empty }
    end

    context 'when a project is passed in' do
      let_it_be(:deploy_keys_project) { create(:deploy_keys_project, :write_access, project: project) }
      let_it_be(:deploy_key) { deploy_keys_project.deploy_key }

      it 'only returns deploy keys with write access' do
        create(:deploy_keys_project, project: project)

        is_expected.to contain_exactly(deploy_key)
      end

      it 'returns deploy keys only for this project' do
        other_project = create(:project)
        create(:deploy_keys_project, :write_access, project: other_project)

        is_expected.to contain_exactly(deploy_key)
      end

      context 'and a specific deploy key is passed in' do
        subject { described_class.with_write_access_for_project(project, deploy_key: specific_deploy_key) }

        context 'and this deploy key is not linked to the project' do
          let(:specific_deploy_key) { create(:deploy_key) }

          it { is_expected.to be_empty }
        end

        context 'and this deploy key has not write access to the project' do
          let(:specific_deploy_key) { create(:deploy_key, deploy_keys_projects: [create(:deploy_keys_project, project: project)]) }

          it { is_expected.to be_empty }
        end

        context 'and this deploy key has write access to the project' do
          let(:specific_deploy_key) { create(:deploy_key, deploy_keys_projects: [create(:deploy_keys_project, :write_access, project: project)]) }

          it { is_expected.to contain_exactly(specific_deploy_key) }
        end
      end
    end
  end
end
