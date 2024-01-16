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
        expect { execute }.to change {
          subgroup_routes_with_old_path.size
        }.by(0).and change {
          subgroup_projects_routes_with_old_path.size
        }.by(0).and change {
          subgroup_routes_with_new_path.size
        }.by(0).and change {
          subgroup_projects_routes_with_new_path.size
        }.by(0)
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
        expect { execute }.to change {
          subgroup_routes_with_old_name.size
        }.by(0).and change {
          subgroup_projects_routes_with_old_name.size
        }.by(0).and change {
          subgroup_routes_with_new_name.size
        }.by(0).and change {
          subgroup_projects_routes_with_new_name.size
        }.by(0)
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
