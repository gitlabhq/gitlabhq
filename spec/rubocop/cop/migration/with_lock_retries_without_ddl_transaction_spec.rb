# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/with_lock_retries_without_ddl_transaction'

describe RuboCop::Cop::Migration::WithLockRetriesWithoutDdlTransaction do
  include CopHelper

  let(:valid_source) { 'class MigrationClass < ActiveRecord::Migration[6.0]; def up; with_lock_retries {}; end; end' }
  let(:invalid_source) { 'class MigrationClass < ActiveRecord::Migration[6.0]; disable_ddl_transaction!; def up; with_lock_retries {}; end; end' }

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `with_lock_retries` is used with `disable_ddl_transaction!` method' do
      inspect_source(invalid_source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers no offense when `with_lock_retries` is used inside an `up` method' do
      inspect_source(valid_source)

      expect(cop.offenses.size).to eq(0)
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source(invalid_source)

      expect(cop.offenses.size).to eq(0)
    end
  end
end
