# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/batch_migrations_post_only'

RSpec.describe RuboCop::Cop::Migration::BatchMigrationsPostOnly do
  before do
    allow(cop).to receive(:in_post_deployment_migration?).and_return post_migration?
  end

  context 'when methods appear in a regular migration' do
    let(:post_migration?) { false }

    it "does not allow 'ensure_batched_background_migration_is_finished' to be called" do
      expect_offense(<<~RUBY)
        ensure_batched_background_migration_is_finished
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This method must only be used in post-deployment migrations.
      RUBY
    end

    it "does not allow 'queue_batched_background_migration' to be called" do
      expect_offense(<<~RUBY)
        queue_batched_background_migration
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This method must only be used in post-deployment migrations.
      RUBY
    end

    it "does not allow 'delete_batched_background_migration' to be called" do
      expect_offense(<<~RUBY)
        delete_batched_background_migration
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This method must only be used in post-deployment migrations.
      RUBY
    end

    it "does not allow 'ensure_batched_background_migration_is_finished' to be called" do
      expect_offense(<<~RUBY)
        finalize_batched_background_migration
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This method must only be used in post-deployment migrations.
      RUBY
    end

    it 'allows arbitrary other method to be called' do
      expect_no_offenses(<<~RUBY)
        foo
      RUBY
    end
  end

  context 'when methods appear in a post-deployment migration' do
    let(:post_migration?) { true }

    it "allows 'ensure_batched_background_migration_is_finished' to be called" do
      expect_no_offenses(<<~RUBY)
        ensure_batched_background_migration_is_finished
      RUBY
    end

    it "allows 'queue_batched_background_migration' to be called" do
      expect_no_offenses(<<~RUBY)
        queue_batched_background_migration
      RUBY
    end

    it "allows 'delete_batched_background_migration' to be called" do
      expect_no_offenses(<<~RUBY)
        delete_batched_background_migration
      RUBY
    end

    it "allows 'ensure_batched_background_migration_is_finished' to be called" do
      expect_no_offenses(<<~RUBY)
        finalize_batched_background_migration
      RUBY
    end

    it 'allows arbitrary other method to be called' do
      expect_no_offenses(<<~RUBY)
        foo
      RUBY
    end
  end
end
