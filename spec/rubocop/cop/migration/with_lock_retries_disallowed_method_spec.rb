# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/with_lock_retries_disallowed_method'

describe RuboCop::Cop::Migration::WithLockRetriesDisallowedMethod do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when `with_lock_retries` block has disallowed method' do
      inspect_source('def change; with_lock_retries { disallowed_method }; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers an offense when `with_lock_retries` block has disallowed methods' do
      source = <<~HEREDOC
      def change
        with_lock_retries do
          disallowed_method

          create_table do |t|
            t.text :text
          end

          other_disallowed_method

          add_column :users, :name
        end
      end
      HEREDOC

      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(2)
        expect(cop.offenses.map(&:line)).to eq([3, 9])
      end
    end

    it 'registers no offense when `with_lock_retries` has only allowed method' do
      inspect_source('def up; with_lock_retries { add_foreign_key :foo, :bar }; end')

      expect(cop.offenses.size).to eq(0)
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source('def change; with_lock_retries { disallowed_method }; end')

      expect(cop.offenses.size).to eq(0)
    end
  end
end
