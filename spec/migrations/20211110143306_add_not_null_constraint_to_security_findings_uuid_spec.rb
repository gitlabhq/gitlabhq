# frozen_string_literal: true
require 'spec_helper'
require_migration!

RSpec.describe AddNotNullConstraintToSecurityFindingsUuid, feature_category: :vulnerability_management do
  let!(:security_findings) { table(:security_findings) }
  let!(:migration) { described_class.new }

  before do
    allow(migration).to receive(:transaction_open?).and_return(false)
    allow(migration).to receive(:with_lock_retries).and_yield
  end

  it 'adds a check constraint' do
    constraint = security_findings.connection.check_constraints(:security_findings).find { |constraint| constraint.expression == "uuid IS NOT NULL" }
    expect(constraint).to be_nil

    migration.up

    constraint = security_findings.connection.check_constraints(:security_findings).find { |constraint| constraint.expression == "uuid IS NOT NULL" }
    expect(constraint).to be_a(ActiveRecord::ConnectionAdapters::CheckConstraintDefinition)
  end
end
