# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/drop_table'

describe RuboCop::Cop::Migration::DropTable do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when in deployment migration' do
    before do
      allow(cop).to receive(:in_deployment_migration?).and_return(true)
    end

    it 'registers an offense' do
      expect_offense(<<~PATTERN)
        def change
          drop_table :table
          ^^^^^^^^^^ #{described_class::MSG}

          add_column(:users, :username, :text)

          execute "DROP TABLE table"
          ^^^^^^^ #{described_class::MSG}

          execute "CREATE UNIQUE INDEX email_index ON users (email);"
        end
      PATTERN
    end
  end

  context 'when in post-deployment migration' do
    before do
      allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
    end

    it 'registers no offense' do
      expect_no_offenses(<<~PATTERN)
        def change
          drop_table :table
          execute "DROP TABLE table"
        end
      PATTERN
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~PATTERN)
        def change
          drop_table :table
          execute "DROP TABLE table"
        end
      PATTERN
    end
  end
end
