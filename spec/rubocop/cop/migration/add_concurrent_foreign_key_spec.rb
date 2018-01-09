require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_concurrent_foreign_key'

describe RuboCop::Cop::Migration::AddConcurrentForeignKey do
  include CopHelper

  let(:cop) { described_class.new }

  context 'outside of a migration' do
    it 'does not register any offenses' do
      inspect_source('def up; add_foreign_key(:projects, :users, column: :user_id); end')

      expect(cop.offenses).to be_empty
    end
  end

  context 'in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when using add_foreign_key' do
      inspect_source('def up; add_foreign_key(:projects, :users, column: :user_id); end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end
  end
end
