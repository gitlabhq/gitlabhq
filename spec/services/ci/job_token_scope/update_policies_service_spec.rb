# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::UpdatePoliciesService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, ci_inbound_job_token_scope_enabled: true) }

  let_it_be(:target_project) { create(:project, :private) }
  let_it_be(:target_group) { create(:group, :private) }

  subject(:execute) do
    described_class.new(project, current_user).execute(target, default_permissions, policies)
  end

  describe '#execute' do
    shared_examples 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end
    end

    shared_examples 'when user does not have permissions to admin project' do
      let(:current_user) { create(:user, developer_of: project) }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end
    end

    shared_examples 'when user does not have permissions to read target' do
      let(:current_user) {  create(:user, maintainer_of: project) }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end
    end

    shared_examples 'when target does not exist' do
      let(:target) { nil }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('The target does not exist')
      end
    end

    shared_examples 'when the job token scope does not exist' do
      let(:another_group) { create(:group) }
      let(:current_user) { create(:user, maintainer_of: project, guest_of: another_group) }

      let(:target) { another_group }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('Unable to find a job token scope for the given project & target')
      end
    end

    shared_examples 'when the policies provided are invalid' do
      let(:policies) { %w[read_issue] }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('Job token policies must be a valid json schema')
      end
    end

    context 'when policies need to be updated for a target project' do
      let(:target) { target_project }

      let_it_be(:project_scope_link) do
        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: target_project,
          default_permissions: true,
          job_token_policies: %w[read_containers],
          direction: :inbound
        )
      end

      let(:default_permissions) { false }
      let(:policies) { %w[read_containers read_packages] }

      it_behaves_like 'when user is not logged in'

      context 'when user is logged in' do
        it_behaves_like 'when user does not have permissions to admin project'
        it_behaves_like 'when user does not have permissions to read target'

        context 'when user has permissions to admin project and read target project' do
          let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_project) }

          it_behaves_like 'when target does not exist'
          it_behaves_like 'when the job token scope does not exist'

          it_behaves_like 'when the policies provided are invalid'

          it 'updates policies for the target project', :aggregate_failures do
            expect(execute).to be_success

            project_link = execute.payload

            expect(project_link.source_project).to eq(project)
            expect(project_link.target_project).to eq(target_project)
            expect(project_link.default_permissions).to be(false)
            expect(project_link.job_token_policies).to eq(%w[read_containers read_packages])
          end

          context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
            before do
              stub_feature_flags(add_policies_to_ci_job_token: false)
            end

            it 'does not update the policies' do
              project_link = Ci::JobToken::ProjectScopeLink.last

              expect(project_link.job_token_policies).to eq(%w[read_containers])
            end
          end
        end
      end
    end

    context 'when policies need to be updated for a target group' do
      let(:target) { target_group }

      let_it_be(:group_scope_link) do
        create(
          :ci_job_token_group_scope_link,
          source_project: project,
          target_group: target_group,
          default_permissions: true,
          job_token_policies: %w[read_containers]
        )
      end

      let(:default_permissions) { false }
      let(:policies) { %w[read_containers read_packages] }

      it_behaves_like 'when user is not logged in'

      context 'when user is logged in' do
        it_behaves_like 'when user does not have permissions to admin project'
        it_behaves_like 'when user does not have permissions to read target'

        context 'when user has permissions to admin project and read target group' do
          let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_group) }

          it_behaves_like 'when target does not exist'
          it_behaves_like 'when the job token scope does not exist'

          it_behaves_like 'when the policies provided are invalid'

          it 'updates policies for the target group', :aggregate_failures do
            expect(execute).to be_success

            group_link = execute.payload

            expect(group_link.source_project).to eq(project)
            expect(group_link.target_group).to eq(target_group)
            expect(group_link.default_permissions).to be(false)
            expect(group_link.job_token_policies).to eq(%w[read_containers read_packages])
          end

          context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
            before do
              stub_feature_flags(add_policies_to_ci_job_token: false)
            end

            it 'does not update the policies' do
              group_link = Ci::JobToken::GroupScopeLink.last

              expect(group_link.job_token_policies).to eq(%w[read_containers])
            end
          end
        end
      end
    end
  end
end
