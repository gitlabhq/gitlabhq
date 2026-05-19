# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Routes::RenameDescendantsService, feature_category: :groups_and_projects do
  let_it_be(:parent_group) { create(:group, name: 'old-name', path: 'old-path') }
  let_it_be(:parent_route) { parent_group.route }
  let_it_be(:subgroups) { create_list(:group, 4, parent: parent_group) }
  let_it_be(:subgroup_projects) { subgroups.map { |subgroup| create(:project, group: subgroup) } }

  let(:subgroup_routes) { Route.for_routable(subgroups) }
  let(:subgroup_projects_routes) { Route.for_routable(subgroup_projects) }

  let(:subgroup_routes_with_old_path) { subgroup_routes.where('path LIKE ?', '%old-path%') }
  let(:subgroup_projects_routes_with_old_path) { subgroup_projects_routes.where('path LIKE ?', '%old-path%') }
  let(:subgroup_routes_with_new_path) { subgroup_routes.where('path LIKE ?', '%new-path%') }
  let(:subgroup_projects_routes_with_new_path) { subgroup_projects_routes.where('path LIKE ?', '%new-path%') }

  let(:subgroup_routes_with_old_name) { subgroup_routes.where('name LIKE ?', '%old-name%') }
  let(:subgroup_projects_routes_with_old_name) { subgroup_projects_routes.where('name LIKE ?', '%old-name%') }
  let(:subgroup_routes_with_new_name) { subgroup_routes.where('name LIKE ?', '%new-name%') }
  let(:subgroup_projects_routes_with_new_name) { subgroup_projects_routes.where('name LIKE ?', '%new-name%') }

  describe '#execute' do
    shared_examples_for 'descendant paths are updated' do
      it do
        expect { execute }.to change {
          subgroup_routes_with_old_path.size
        }.from(4).to(0).and change {
          subgroup_projects_routes_with_old_path.size
        }.from(4).to(0).and change {
          subgroup_routes_with_new_path.size
        }.from(0).to(4).and change {
          subgroup_projects_routes_with_new_path.size
        }.from(0).to(4)
      end
    end

    shared_examples_for 'descendant paths are not updated' do
      it do
        expect { execute }
          .to not_change { subgroup_routes_with_old_path.size }
          .and not_change { subgroup_projects_routes_with_old_path.size }
          .and not_change { subgroup_routes_with_new_path.size }
          .and not_change { subgroup_projects_routes_with_new_path.size }
      end
    end

    shared_examples_for 'descendant names are updated' do
      it do
        expect { execute }.to change {
          subgroup_routes_with_old_name.size
        }.from(4).to(0).and change {
          subgroup_projects_routes_with_old_name.size
        }.from(4).to(0).and change {
          subgroup_routes_with_new_name.size
        }.from(0).to(4).and change {
          subgroup_projects_routes_with_new_name.size
        }.from(0).to(4)
      end
    end

    shared_examples_for 'descendant names are not updated' do
      it do
        expect { execute }
          .to not_change { subgroup_routes_with_old_name.size }
          .and not_change { subgroup_projects_routes_with_old_name.size }
          .and not_change { subgroup_routes_with_new_name.size }
          .and not_change { subgroup_projects_routes_with_new_name.size }
      end
    end

    shared_examples_for 'creates redirect_routes for all descendants' do
      let(:subgroup_redirect_routes) { RedirectRoute.where(source: subgroups) }
      let(:subgroup_projects_redirect_routes) { RedirectRoute.where(source: subgroup_projects) }

      it do
        expect { execute }.to change {
          subgroup_redirect_routes.where('path LIKE ?', '%old-path%').size
        }.from(0).to(4).and change {
          subgroup_projects_redirect_routes.where('path LIKE ?', '%old-path%').size
        }.from(0).to(4)
      end
    end

    shared_examples_for 'does not create any redirect_routes' do
      it do
        expect { execute }.not_to change { RedirectRoute.count }
      end
    end

    subject(:execute) do
      described_class.new(parent_route).execute(changes)
    end

    before do
      parent_route.name = 'new-name'
      parent_route.path = 'new-path'
    end

    context 'on updating both name and path' do
      let!(:changes) do
        {
          path: { saved: true, old_value: 'old-path' },
          name: { saved: true, old_value: 'old-name' }
        }
      end

      it_behaves_like 'descendant paths are updated'
      it_behaves_like 'descendant names are updated'
      it_behaves_like 'creates redirect_routes for all descendants'
    end

    context 'on updating only path' do
      let!(:changes) do
        {
          path: { saved: true, old_value: 'old-path' },
          name: { saved: false, old_value: 'old-name' }
        }
      end

      it_behaves_like 'descendant paths are updated'
      it_behaves_like 'descendant names are not updated'
      it_behaves_like 'creates redirect_routes for all descendants'
    end

    context 'on updating only name' do
      let!(:changes) do
        {
          path: { saved: false, old_value: 'old-path' },
          name: { saved: true, old_value: 'old-name' }
        }
      end

      it_behaves_like 'descendant paths are not updated'
      it_behaves_like 'descendant names are updated'
      it_behaves_like 'does not create any redirect_routes'
    end

    context 'on not updating both path and name' do
      let!(:changes) do
        {
          path: { saved: false, old_value: 'old-path' },
          name: { saved: false, old_value: 'old-name' }
        }
      end

      it_behaves_like 'descendant paths are not updated'
      it_behaves_like 'descendant names are not updated'
      it_behaves_like 'does not create any redirect_routes'
    end

    context 'when cells claims are enabled' do
      before do
        stub_config_cell(enabled: true)
      end

      let!(:changes) do
        {
          path: { saved: true, old_value: 'old-path' },
          name: { saved: true, old_value: 'old-name' }
        }
      end

      context 'for route claims when descendants have "/" in path' do
        it 'does not schedule BulkClaimsWorker since descendants are not claimable' do
          # All descendant routes contain '/' so none pass the if condition
          expect(Cells::BulkClaimsWorker).not_to receive(:perform_async).with('Route', 'path', anything)

          execute
        end
      end

      context 'when only name changes' do
        let!(:changes) do
          {
            path: { saved: false, old_value: 'old-path' },
            name: { saved: true, old_value: 'old-name' }
          }
        end

        it 'does not collect route claims metadata' do
          expect(Cells::BulkClaimsWorker).not_to receive(:perform_async).with('Route', 'path', anything)

          execute
        end
      end

      context 'for route claims when descendants are claimable' do
        before do
          # Stub the if condition to always return true to exercise full code path
          # In practice, descendant routes always have '/' and are not claimable
          allow(Route).to receive(:cells_claims_attributes).and_return({
            path: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ROUTES,
              feature_flag: :cells_claims_routes,
              if: ->(_record) { true }
            }
          })
          allow(parent_route).to receive(:run_after_commit).and_yield
        end

        it 'collects destroy metadata and schedules BulkClaimsWorker' do
          expect(Cells::BulkClaimsWorker).to receive(:perform_async).with(
            'Route', 'path', hash_including('destroy_metadata')
          )
          expect(Cells::BulkClaimsWorker).to receive(:perform_async).with(
            'Route', 'path', hash_including('create_record_ids')
          )
          # RedirectRoute claims are also scheduled via run_after_commit
          allow(Cells::BulkClaimsWorker).to receive(:perform_async).with(
            'RedirectRoute', 'path', anything
          )

          execute
        end
      end

      context 'for redirect route claims' do
        before do
          allow(parent_route).to receive(:run_after_commit).and_yield
        end

        it 'schedules BulkClaimsWorker with create_record_ids for inserted redirect routes' do
          expect(Cells::BulkClaimsWorker).to receive(:perform_async).with(
            'RedirectRoute', 'path', hash_including('create_record_ids')
          )

          execute
        end

        context 'when all redirect route inserts conflict' do
          before do
            # Pre-create redirect routes so insert_all returns no new IDs
            subgroups.each do |subgroup|
              RedirectRoute.find_or_create_by!(
                source: subgroup,
                path: subgroup.route.path
              )
            end
            subgroup_projects.each do |project|
              RedirectRoute.find_or_create_by!(
                source: project,
                path: project.route.path
              )
            end
          end

          it 'does not schedule BulkClaimsWorker for redirect routes' do
            expect(Cells::BulkClaimsWorker).not_to receive(:perform_async).with(
              'RedirectRoute', 'path', anything
            )

            execute
          end
        end
      end
    end

    context 'when `changes` are not in the expected format' do
      let!(:changes) do
        {
          not_path: { saved: false, old_value: 'old-path' },
          name: { saved: true, old_value: 'old-name' }
        }
      end

      it 'errors out' do
        expect { execute }.to raise_error(KeyError)
      end
    end

    context 'for batching' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)
      end

      let!(:changes) do
        {
          path: { saved: true, old_value: 'old-path' },
          name: { saved: true, old_value: 'old-name' }
        }
      end

      it 'bulk updates and bulk inserts records in batches' do
        query_recorder = ActiveRecord::QueryRecorder.new do
          execute
        end

        # There are 8 descendants to this group.
        # 4 subgroups, and 1 project each in each subgroup == total of 8.
        # With a batch size of 2, that is
        # 4 queries to update `routes` and 4 queries to insert `redirect_routes`
        update_routes_queries = query_recorder.log.grep(
          /INSERT INTO "routes" .* ON CONFLICT \("id"\) DO UPDATE SET/
        )

        insert_redirect_routes_queries = query_recorder.log.grep(
          /INSERT INTO "redirect_routes" .* ON CONFLICT \(lower\(\(path\)::text\) varchar_pattern_ops\) DO NOTHING/
        )

        expect(update_routes_queries.count).to eq(4)
        expect(insert_redirect_routes_queries.count).to eq(4)
      end
    end
  end
end
