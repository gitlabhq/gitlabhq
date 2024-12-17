# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::BulkDeleteRunnersService, '#execute', feature_category: :fleet_visibility do
  subject(:execute) { described_class.new(**service_args).execute }

  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be_with_refind(:owner_user) { create(:user) } # discard memoized ci_owned_runners
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:user) {}
  let(:service_args) { { runners: runners_arg, current_user: user } }
  let(:runners_arg) {}

  context 'with runners specified' do
    let!(:instance_runner) { create(:ci_runner) }
    let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let!(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    shared_examples 'a service deleting runners in bulk' do
      let!(:expected_deleted_ids) { expected_deleted_runners.map(&:id) }

      it 'destroys runners', :aggregate_failures do
        expect { execute }.to change { Ci::Runner.count }.by(-expected_deleted_ids.count)

        expect(execute).to be_success
        expect(execute.payload).to eq(
          deleted_count: expected_deleted_ids.count,
          deleted_ids: expected_deleted_ids,
          deleted_models: expected_deleted_runners,
          errors: []
        )
        expect { project_runner.runner_projects.first.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expected_deleted_runners.each do |deleted_runner|
          expect(deleted_runner[:errors]).to be_nil
          expect { deleted_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with too many runners specified' do
        before do
          stub_const("#{described_class}::RUNNER_LIMIT", 1)
        end

        it 'deletes only first RUNNER_LIMIT runners', :aggregate_failures do
          expect { execute }.to change { Ci::Runner.count }.by(-1)

          expect(execute).to be_success
          expect(execute.payload).to match(
            {
              deleted_count: 1,
              deleted_ids: a_collection_containing_exactly(an_instance_of(Integer)),
              deleted_models: a_collection_containing_exactly(an_instance_of(::Ci::Runner)),
              errors: ["Can only delete up to 1 runners per call. Ignored the remaining runner(s)."]
            })
          expect(expected_deleted_ids).to include(execute.payload[:deleted_ids].first)
          expect(expected_deleted_runners).to include(execute.payload[:deleted_models].first)
        end
      end
    end

    context 'when the user cannot delete runners' do
      let(:runners_arg) { Ci::Runner.all }

      context 'when user is not group owner' do
        before do
          group.add_developer(user)
        end

        let(:user) { create(:user) }

        it 'does not delete any runner and returns error', :aggregate_failures do
          expect { execute }.not_to change { Ci::Runner.count }
          expect(execute[:errors]).to match_array("User does not have permission to delete any of the runners")
        end
      end

      context 'when user is not part of the group' do
        let(:user) { create(:user) }

        it 'does not delete any runner and returns error', :aggregate_failures do
          expect { execute }.not_to change { Ci::Runner.count }
          expect(execute[:errors]).to match_array("User does not have permission to delete any of the runners")
        end
      end
    end

    context 'when the user can delete runners' do
      context 'when user is an admin', :enable_admin_mode do
        include_examples 'a service deleting runners in bulk' do
          let(:runners_arg) { Ci::Runner.all }
          let!(:expected_deleted_runners) { [instance_runner, group_runner, project_runner] }
          let(:user) { admin_user }
        end

        context 'with a runner already deleted' do
          before do
            group_runner.destroy!
          end

          include_examples 'a service deleting runners in bulk' do
            let(:runners_arg) { Ci::Runner.all }
            let!(:expected_deleted_runners) { [instance_runner, project_runner] }
            let(:user) { admin_user }
          end
        end

        context 'when deleting a single runner' do
          let(:runners_arg) { Ci::Runner.all }

          it 'avoids N+1 cached queries', :use_sql_query_cache, :request_store do
            # Run this once to establish a baseline
            control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              execute
            end

            additional_runners = 1

            create_list(:ci_runner, 1 + additional_runners, :instance)
            create_list(:ci_runner, 1 + additional_runners, :group, groups: [group])
            create_list(:ci_runner, 1 + additional_runners, :project, projects: [project])

            service = described_class.new(runners: runners_arg, current_user: user)

            # Base cost per runner is:
            #  - 1 `SELECT * FROM "taggings"` query
            #  - 1 `SAVEPOINT` query
            #  - 1 `DELETE FROM "ci_runners"` query
            #  - 1 `RELEASE SAVEPOINT` query
            # Project runners have an additional query:
            #  - 1 `DELETE FROM "ci_runner_projects"` query, given the call to `destroy_all`
            instance_runner_cost = 4
            group_runner_cost = 4
            project_runner_cost = 5
            expect { service.execute }
              .not_to exceed_all_query_limit(control_count)
              .with_threshold(additional_runners * (instance_runner_cost + group_runner_cost + project_runner_cost))
          end
        end
      end

      context 'when user is group owner' do
        before do
          group.add_owner(user)
        end

        include_examples 'a service deleting runners in bulk' do
          let(:runners_arg) { Ci::Runner.not_instance_type }
          let!(:expected_deleted_runners) { [group_runner, project_runner] }
          let(:user) { owner_user }
        end

        context 'with a runner non-authorised to be deleted' do
          let(:runners_arg) { Ci::Runner.all }
          let!(:expected_deleted_runners) { [project_runner] }
          let(:user) { owner_user }

          it 'destroys only authorised runners', :aggregate_failures do
            allow(Ability).to receive(:allowed?).and_call_original
            expect(Ability).to receive(:allowed?).with(user, :delete_runner, instance_runner).and_return(false)

            expect { execute }.to change { Ci::Runner.count }.by(-2)

            expect(execute).to be_success
            expect(execute.payload).to eq(
              deleted_count: 2,
              deleted_ids: [group_runner.id, project_runner.id],
              deleted_models: [group_runner, project_runner],
              errors: ["User does not have permission to delete runner(s) ##{instance_runner.id}"]
            )
          end
        end
      end
    end

    context 'with no arguments specified' do
      let(:runners_arg) { nil }
      let(:user) { owner_user }

      it 'returns 0 deleted runners' do
        expect(execute).to be_success
        expect(execute.payload).to eq(deleted_count: 0, deleted_ids: [], deleted_models: [], errors: [])
      end
    end
  end
end
