# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Handlers::CleanupDataHandler, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:current_user) { create(:user) }

  subject(:cleanup_data_handler) { described_class.new(work_item: work_item, current_user: current_user) }

  it 'runs all widget callbacks' do
    create_service_params = {
      work_item: anything, target_work_item: anything, current_user: current_user, params: {}
    }

    work_item.widgets.flat_map(&:sync_data_callback_class).each do |callback_class|
      allow_next_instance_of(callback_class, **create_service_params) do |callback_instance|
        expect(callback_instance).to receive(:post_move_cleanup)
      end
    end

    cleanup_data_handler.execute
  end

  it 'runs all non-widget callbacks' do
    create_service_params = {
      work_item: anything, target_work_item: anything, current_user: current_user, params: {}
    }

    WorkItem.non_widgets.filter_map do |association_name|
      sync_callback_class = WorkItem.sync_callback_class(association_name)
      next if sync_callback_class.nil?

      allow_next_instance_of(sync_callback_class, **create_service_params) do |callback_instance|
        expect(callback_instance).to receive(:post_move_cleanup)
      end
    end

    cleanup_data_handler.execute
  end
end
