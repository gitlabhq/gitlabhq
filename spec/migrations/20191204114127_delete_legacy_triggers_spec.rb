# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191204114127_delete_legacy_triggers.rb')

describe DeleteLegacyTriggers, :migration, schema: 2019_11_25_140458 do
  let(:ci_trigger_table) { table(:ci_triggers) }
  let(:user) { table(:users).create!(name: 'test', email: 'test@example.com', projects_limit: 1) }

  before do
    @trigger_with_user = ci_trigger_table.create!(owner_id: user.id)
    ci_trigger_table.create!(owner_id: nil)
    ci_trigger_table.create!(owner_id: nil)
  end

  it 'removes legacy triggers which has null owner_id' do
    expect do
      migrate!
    end.to change(ci_trigger_table, :count).by(-2)

    expect(ci_trigger_table.all).to eq([@trigger_with_user])
  end
end
