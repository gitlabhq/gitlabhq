# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropSoftwareLicensesTempIndex, feature_category: :security_policy_management do
  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes('software_licenses').map(&:name))
          .to include(described_class::INDEX_NAME)
      }

      migration.after -> {
        expect(ActiveRecord::Base.connection.indexes('software_licenses').map(&:name))
          .not_to include(described_class::INDEX_NAME)
      }
    end
  end
end
