# frozen_string_literal: true

require 'spec_helper'
require_migration!('drop_position_from_security_findings')

RSpec.describe DropPositionFromSecurityFindings, feature_category: :vulnerability_management do
  let(:events) { table(:security_findings) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(events.column_names).to include('position')
      }

      migration.after -> {
        events.reset_column_information
        expect(events.column_names).not_to include('position')
      }
    end
  end
end
