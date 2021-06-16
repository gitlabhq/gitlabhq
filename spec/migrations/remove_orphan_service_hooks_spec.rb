# frozen_string_literal: true

require 'spec_helper'

require_migration!
require_migration!('add_web_hooks_service_foreign_key')

RSpec.describe RemoveOrphanServiceHooks, schema: 20201203123201 do
  let(:web_hooks) { table(:web_hooks) }
  let(:services) { table(:services) }

  before do
    services.create!
    web_hooks.create!(service_id: services.first.id, type: 'ServiceHook')
    web_hooks.create!(service_id: nil)

    AddWebHooksServiceForeignKey.new.down
    web_hooks.create!(service_id: non_existing_record_id, type: 'ServiceHook')
    AddWebHooksServiceForeignKey.new.up
  end

  it 'removes service hooks where the referenced service does not exist', :aggregate_failures do
    expect { RemoveOrphanServiceHooks.new.up }.to change { web_hooks.count }.by(-1)
    expect(web_hooks.where.not(service_id: services.select(:id)).count).to eq(0)
  end
end
