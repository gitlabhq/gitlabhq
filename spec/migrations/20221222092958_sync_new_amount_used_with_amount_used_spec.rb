# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe SyncNewAmountUsedWithAmountUsed, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:project_usages) { table(:ci_project_monthly_usages) }
  let(:migration) { described_class.new }

  before do
    # Disabling the trigger temporarily to allow records being created with out-of-sync
    # `new_amount_used` and `amount_used`. This will simulate existing records before
    # we add the trigger.
    ActiveRecord::Base.connection
      .execute("ALTER TABLE ci_project_monthly_usages DISABLE TRIGGER sync_projects_amount_used_columns")

    this_month = Time.now.utc.beginning_of_month
    last_month = 1.month.ago.utc.beginning_of_month
    last_year = 1.year.ago.utc.beginning_of_month

    project_usages.create!(project_id: 1, date: last_year)
    project_usages.create!(project_id: 1, date: this_month, amount_used: 10, new_amount_used: 0)
    project_usages.create!(project_id: 1, date: last_month, amount_used: 20, new_amount_used: 0)

    project_usages.create!(project_id: 2, date: last_year)
    project_usages.create!(project_id: 2, date: this_month, amount_used: 30, new_amount_used: 0)
    project_usages.create!(project_id: 2, date: last_month, amount_used: 40, new_amount_used: 0)

    ActiveRecord::Base.connection
      .execute("ALTER TABLE ci_project_monthly_usages ENABLE TRIGGER sync_projects_amount_used_columns")
  end

  describe '#up' do
    it "doesnt change new_amount_used values" do
      data = project_usages.all
      data.each do |item|
        expect { migration.up }.to not_change { item.new_amount_used }
      end
    end
  end

  describe '#down' do
    it 'updates `new_amount_used` with values from `amount_used`' do
      expect(project_usages.where(new_amount_used: 0).count).to eq(6)

      migration.down

      expect(project_usages.where(new_amount_used: 0).count).to eq(2)
      expect(project_usages.order(:id).pluck(:new_amount_used))
        .to contain_exactly(0, 0, 10, 20, 30, 40)
    end
  end
end
