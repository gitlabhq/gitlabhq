# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddNotificationsWorkItemWidget, :migration, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }

  describe '#up' do
    it 'creates notifications widget definition in all types' do
      work_item_definitions.where(name: 'Notifications').delete_all

      expect { migrate! }.to change { work_item_definitions.count }.by(7)
      expect(work_item_definitions.all.pluck(:name)).to include('Notifications')
    end
  end

  describe '#down' do
    it 'removes definitions for notifications widget' do
      migrate!

      expect { migration.down }.to change { work_item_definitions.count }.by(-7)
      expect(work_item_definitions.all.pluck(:name)).not_to include('Notifications')
    end
  end
end
