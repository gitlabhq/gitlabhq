# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeUserTypeMigration, feature_category: :devops_reports do
  it 'finalizes MigrateHumanUserType migration' do
    expect(described_class).to be_finalize_background_migration_of('MigrateHumanUserType')

    migrate!
  end
end
