# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/performance/active_record_subtransactions'

RSpec.describe RuboCop::Cop::Performance::ActiveRecordSubtransactions do
  let(:message) { described_class::MSG }

  context 'when calling #transaction with only requires_new: true' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        ApplicationRecord.transaction(requires_new: true) do
                                      ^^^^^^^^^^^^^^^^^^ #{message}
          Project.create!(name: 'MyProject')
        end
      RUBY
    end
  end

  context 'when passing multiple arguments to #transaction, including requires_new: true' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        ApplicationRecord.transaction(isolation: :read_committed, requires_new: true) do
                                                                  ^^^^^^^^^^^^^^^^^^ #{message}
          Project.create!(name: 'MyProject')
        end
      RUBY
    end
  end

  context 'when calling #transaction with requires_new: false' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        ApplicationRecord.transaction(requires_new: false) do
          Project.create!(name: 'MyProject')
        end
      RUBY
    end
  end

  context 'when calling #transaction with other options' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        ApplicationRecord.transaction(isolation: :read_committed) do
          Project.create!(name: 'MyProject')
        end
      RUBY
    end
  end

  context 'when calling #transaction with no arguments' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        ApplicationRecord.transaction do
          Project.create!(name: 'MyProject')
        end
      RUBY
    end
  end
end
