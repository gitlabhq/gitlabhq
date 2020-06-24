# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/migration/with_lock_retries_with_change'

RSpec.describe RuboCop::Cop::Migration::WithLockRetriesWithChange, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `with_lock_retries` is used inside a `change` method' do
      inspect_source('def change; with_lock_retries {}; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers no offense when `with_lock_retries` is used inside an `up` method' do
      inspect_source('def up; with_lock_retries {}; end')

      expect(cop.offenses.size).to eq(0)
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source('def change; with_lock_retries {}; end')

      expect(cop.offenses.size).to eq(0)
    end
  end
end
