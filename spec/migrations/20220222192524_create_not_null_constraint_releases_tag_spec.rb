# frozen_string_literal: true
require 'spec_helper'
require_migration!

RSpec.describe CreateNotNullConstraintReleasesTag, feature_category: :release_orchestration do
  let!(:releases) { table(:releases) }
  let!(:migration) { described_class.new }

  before do
    allow(migration).to receive(:transaction_open?).and_return(false)
    allow(migration).to receive(:with_lock_retries).and_yield
  end

  it 'adds a check constraint to tags' do
    constraint = releases.connection.check_constraints(:releases).find { |constraint| constraint.expression == "tag IS NOT NULL" }
    expect(constraint).to be_nil

    migration.up

    constraint = releases.connection.check_constraints(:releases).find { |constraint| constraint.expression == "tag IS NOT NULL" }
    expect(constraint).to be_a(ActiveRecord::ConnectionAdapters::CheckConstraintDefinition)
  end
end
