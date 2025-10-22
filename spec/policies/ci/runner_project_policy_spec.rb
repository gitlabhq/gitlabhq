# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProjectPolicy, feature_category: :runner_core do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:developer_project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project, other_project, developer_project]) }
  let_it_be(:owner_runner_project) { project.runner_projects.first }
  let_it_be(:member_runner_project) { other_project.runner_projects.first }
  let_it_be(:developer_runner_project) { developer_project.runner_projects.first }

  let_it_be(:owner) { create(:user, owner_of: [project, other_project]) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project], developer_of: developer_project) }
  let_it_be(:developer) { create(:user, developer_of: [project, other_project]) }
  let_it_be(:reporter) { create(:user, reporter_of: [project, other_project]) }
  let_it_be(:guest) { create(:user, guest_of: [project, other_project]) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:anonymous) { nil }

  let_it_be(:locked_runner) { create(:ci_runner, :project, :locked, projects: [project, other_project]) }
  let_it_be(:locked_runner_project) { locked_runner.runner_projects.last }

  let(:runner_project) { member_runner_project }

  subject(:policy) { described_class.new(user, runner_project) }

  describe 'ability :unassign_runner' do
    shared_examples 'unassign_runner for user with project access' do |allowed:|
      if allowed
        it { is_expected.to be_allowed(:unassign_runner) }
      else
        it { is_expected.to be_disallowed(:unassign_runner) }
      end

      context 'when developer of project' do
        let(:runner_project) { developer_runner_project }

        it { is_expected.to be_disallowed(:unassign_runner) }
      end

      context 'with locked runner' do
        let(:runner_project) { locked_runner_project }

        it { is_expected.to be_disallowed(:unassign_runner) }
      end

      context 'with owner runner project (assigned to owner project)' do
        let(:runner_project) { owner_runner_project }

        it { is_expected.to be_disallowed(:unassign_runner) }
      end
    end

    where(:user) do
      [
        ref(:anonymous),
        ref(:non_member),
        ref(:guest),
        ref(:reporter),
        ref(:developer)
      ]
    end

    with_them do
      it { is_expected.to be_disallowed(:unassign_runner) }
    end

    context 'when user is maintainer' do
      let(:user) { maintainer }

      it_behaves_like 'unassign_runner for user with project access', allowed: true
    end

    context 'when user is owner' do
      let(:user) { owner }

      it_behaves_like 'unassign_runner for user with project access', allowed: true
    end

    context 'when user is admin' do
      let(:user) { admin }

      it { is_expected.to be_disallowed(:unassign_runner) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:unassign_runner) }

        context 'with locked runner' do
          let(:runner_project) { locked_runner_project }

          it { is_expected.to be_allowed(:unassign_runner) }
        end

        context 'with owner runner project (assigned to owner project)' do
          let(:runner_project) { owner_runner_project }

          it { is_expected.to be_disallowed(:unassign_runner) }
        end
      end
    end
  end
end
