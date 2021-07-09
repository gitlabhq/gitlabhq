# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_index_creation'

RSpec.describe RuboCop::Cop::Migration::PreventIndexCreation do
  subject(:cop) { described_class.new }

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when adding an index to a forbidden table' do
      it 'registers an offense when add_index is used' do
        expect_offense(<<~RUBY)
          def change
            add_index :ci_builds, :protected
            ^^^^^^^^^ Adding new index to ci_builds is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
          end
        RUBY
      end

      it 'registers an offense when add_concurrent_index is used' do
        expect_offense(<<~RUBY)
          def change
            add_concurrent_index :ci_builds, :protected
            ^^^^^^^^^^^^^^^^^^^^ Adding new index to ci_builds is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
          end
        RUBY
      end
    end

    context 'when adding an index to a regular table' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def change
            add_index :ci_pipelines, :locked
          end
        RUBY
      end
    end
  end

  context 'when outside of migration' do
    it 'does not register an offense' do
      expect_no_offenses('def change; add_index :table, :column; end')
    end
  end
end
