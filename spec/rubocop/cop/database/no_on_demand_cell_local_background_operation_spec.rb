# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/no_on_demand_cell_local_background_operation'

RSpec.describe RuboCop::Cop::Database::NoOnDemandCellLocalBackgroundOperation, feature_category: :database do
  let(:allowed_file) { 'app/workers/database/background_operation/cron_enqueue_worker.rb' }
  let(:other_file) { 'app/services/random_service.rb' }

  context 'when called from an arbitrary file' do
    it 'registers an offense for fully-qualified WorkerCellLocal.enqueue' do
      expect_offense(<<~RUBY, other_file)
        Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue('Klass', 'table', 'id')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not enqueue Gitlab::Database::BackgroundOperation::WorkerCellLocal on-demand.[...]
      RUBY
    end

    it 'does not register an offense for Worker.enqueue (organization scoped)' do
      expect_no_offenses(<<~RUBY, other_file)
        Gitlab::Database::BackgroundOperation::Worker.enqueue(
          'Klass', 'table', 'id', organization: org, user: user
        )
      RUBY
    end

    it 'does not register an offense for unrelated .enqueue calls' do
      expect_no_offenses(<<~RUBY, other_file)
        Sidekiq::Client.enqueue(MyWorker, 1, 2)
      RUBY
    end

    it 'registers an offense for absolute-qualified WorkerCellLocal.enqueue' do
      expect_offense(<<~RUBY, other_file)
        ::Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue('Klass', 'table', 'id')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not enqueue Gitlab::Database::BackgroundOperation::WorkerCellLocal on-demand.[...]
      RUBY
    end
  end

  context 'when called from the allowlisted CronEnqueueWorker file' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, allowed_file)
        Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue('Klass', 'table', 'id')
      RUBY
    end
  end
end
