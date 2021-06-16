# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropAlertsServiceData do
  let_it_be(:alerts_service_data) { table(:alerts_service_data) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(alerts_service_data.create!(service_id: 1)).to be_a alerts_service_data
      }

      migration.after -> {
        expect { alerts_service_data.create!(service_id: 1) }
          .to raise_error(ActiveRecord::StatementInvalid, /UndefinedTable/)
      }
    end
  end
end
