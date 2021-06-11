# frozen_string_literal: true

require 'spec_helper'

require_migration!
require_migration!('add_not_valid_foreign_key_to_group_hooks')

RSpec.describe RemoveRecordsWithoutGroupFromWebhooksTable, schema: 20210330091751 do
  let(:web_hooks) { table(:web_hooks) }
  let(:groups) { table(:namespaces) }

  before do
    group = groups.create!(name: 'gitlab', path: 'gitlab-org')
    web_hooks.create!(group_id: group.id, type: 'GroupHook')
    web_hooks.create!(group_id: nil)

    AddNotValidForeignKeyToGroupHooks.new.down
    web_hooks.create!(group_id: non_existing_record_id, type: 'GroupHook')
    AddNotValidForeignKeyToGroupHooks.new.up
  end

  it 'removes group hooks where the referenced group does not exist', :aggregate_failures do
    expect { RemoveRecordsWithoutGroupFromWebhooksTable.new.up }.to change { web_hooks.count }.by(-1)
    expect(web_hooks.where.not(group_id: groups.select(:id)).count).to eq(0)
    expect(web_hooks.where.not(group_id: nil).count).to eq(1)
  end
end
