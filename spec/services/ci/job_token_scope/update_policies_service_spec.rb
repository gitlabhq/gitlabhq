# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::UpdatePoliciesService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, ci_inbound_job_token_scope_enabled: true) }

  let_it_be(:target_project) { create(:project, :private) }
  let_it_be(:target_group) { create(:group, :private) }
  let_it_be(:event) { 'action_on_job_token_allowlist_entry' }

  subject(:execute) do
    described_class.new(project, current_user).execute(target, default_permissions, policies)
  end

  before do
    allow(project).to receive(:job_token_policies_enabled?).and_return(true)
  end

  describe '#execute' do
    shared_examples 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when user does not have permissions to admin project' do
      let(:current_user) { create(:user, developer_of: project) }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when user does not have permissions to read target' do
      let(:current_user) {  create(:user, maintainer_of: project) }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('You have insufficient permission to update this job token scope')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when target does not exist' do
      let(:target) { nil }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('The target does not exist')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when the job token scope does not exist' do
      let(:another_group) { create(:group) }
      let(:current_user) { create(:user, maintainer_of: project, guest_of: another_group) }

      let(:target) { another_group }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('Unable to find a job token scope for the given project & target')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when the policies provided are invalid' do
      let(:policies) { %w[read_issue] }

      it 'returns an error' do
        expect(execute).to be_error
        expect(execute.message).to eq('Job token policies must be a valid json schema')
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'when job token policies are disabled' do
      before do
        allow(project).to receive(:job_token_policies_enabled?).and_return(false)
      end

      it 'returns an error and does not update the policies' do
        expect(execute).to be_error
        expect(execute.message).to eq('Failed to update job token scope')
        expect(scope.reload.job_token_policies).to eq(%w[read_deployments])
      end

      it_behaves_like 'internal event not tracked'
    end

    shared_examples 'event tracking for project scope' do
      it 'logs to Snowplow, Redis, and product analytics tooling', :clean_gitlab_redis_shared_state do
        self_referential = target == project

        expected_attributes = {
          project: project,
          category: 'InternalEventTracking',
          additional_properties: {
            label: anything,
            property: 'project_scope_link',
            action_name: 'updated',
            default_permissions: default_permissions.to_s,
            self_referential: self_referential.to_s
          }
        }

        all_metrics = [
          'count_distinct_job_token_allowlist_entries_for_projects',
          'count_distinct_projects_with_job_token_allowlist_entries',
          ('count_distinct_projects_with_job_token_allowlist_entries_for_itself' if self_referential)
        ].compact.flat_map { |metric| ["redis_hll_counters.#{metric}_weekly", "redis_hll_counters.#{metric}_monthly"] }

        expect { subject }
          .to trigger_internal_events(event)
          .with(expected_attributes)
          .and increment_usage_metrics(all_metrics)
      end
    end

    shared_examples 'event tracking for group scope' do
      it 'logs to Snowplow, Redis, and product analytics tooling', :clean_gitlab_redis_shared_state do
        expected_attributes = {
          project: project,
          category: 'InternalEventTracking',
          additional_properties: {
            label: anything,
            property: 'group_scope_link',
            action_name: 'updated',
            default_permissions: default_permissions.to_s,
            self_referential: 'false'
          }
        }

        all_metrics = %w[
          count_distinct_job_token_allowlist_entries_for_groups
          count_distinct_projects_with_job_token_allowlist_entries
        ].flat_map { |metric| ["redis_hll_counters.#{metric}_weekly", "redis_hll_counters.#{metric}_monthly"] }

        expect { subject }
          .to trigger_internal_events(event)
          .with(expected_attributes)
          .and increment_usage_metrics(all_metrics)
      end
    end

    context 'when policies need to be updated for a target project' do
      let(:target) { target_project }

      let_it_be(:scope) do
        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: target_project,
          default_permissions: true,
          job_token_policies: %w[read_deployments],
          direction: :inbound
        )
      end

      let(:default_permissions) { false }
      let(:policies) { %w[read_deployments read_packages] }

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
            expect(project_link.job_token_policies).to eq(%w[read_deployments read_packages])
          end

          it_behaves_like 'event tracking for project scope'
          it_behaves_like 'when job token policies are disabled'

          context 'when default permissions are not updated' do
            let(:default_permissions) { true }

            it_behaves_like 'internal event not tracked'
          end

          context 'when the target project is the current project' do
            let_it_be(:target) { project }

            context 'when the job token scope does not exist yet' do
              it 'creates a new job token scope', :aggregate_failures do
                expect(execute).to be_success

                project_link = execute.payload

                expect(project_link.source_project).to eq(project)
                expect(project_link.target_project).to eq(project)
                expect(project_link.default_permissions).to be(false)
                expect(project_link.job_token_policies).to eq(%w[read_deployments read_packages])
              end

              it_behaves_like 'event tracking for project scope'
            end

            context 'when the job token scope already exists' do
              before do
                scope.update!(target_project: project)
              end

              it 'updates the existing job token scope', :aggregate_failures do
                expect(execute).to be_success

                project_link = scope.reload

                expect(project_link.default_permissions).to be(false)
                expect(project_link.job_token_policies).to eq(%w[read_deployments read_packages])
              end
            end
          end
        end
      end
    end

    context 'when policies need to be updated for a target group' do
      let(:target) { target_group }

      let_it_be(:scope) do
        create(
          :ci_job_token_group_scope_link,
          source_project: project,
          target_group: target_group,
          default_permissions: true,
          job_token_policies: %w[read_deployments]
        )
      end

      let(:default_permissions) { false }
      let(:policies) { %w[read_deployments read_packages] }

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
            expect(group_link.job_token_policies).to eq(%w[read_deployments read_packages])
          end

          it_behaves_like 'event tracking for group scope'
          it_behaves_like 'when job token policies are disabled'

          context 'when default permissions are not updated' do
            let(:default_permissions) { true }

            it_behaves_like 'internal event not tracked'
          end
        end
      end
    end
  end
end
