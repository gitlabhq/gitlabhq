# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:lock_writes', :reestablished_active_record_base, feature_category: :cell do
  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db/validate_config'
    Rake.application.rake_require 'tasks/gitlab/db/lock_writes'
  end

  let(:table_locker) { instance_double(Gitlab::Database::TablesLocker) }
  let(:logger) { instance_double(Logger, level: nil) }
  let(:dry_run) { false }
  let(:verbose) { false }

  before do
    allow(Logger).to receive(:new).with($stdout).and_return(logger)
    allow(Gitlab::Database::TablesLocker).to receive(:new).with(
      logger: logger, dry_run: dry_run
    ).and_return(table_locker)
  end

  shared_examples "call table locker" do |method|
    let(:log_level) { verbose ? Logger::INFO : Logger::WARN }

    it "creates TablesLocker with dry run set and calls #{method}" do
      expect(logger).to receive(:level=).with(log_level)
      expect(table_locker).to receive(method)

      run_rake_task("gitlab:db:#{method}")
    end
  end

  describe 'lock_writes' do
    context 'when environment sets DRY_RUN to true' do
      let(:dry_run) { true }

      before do
        stub_env('DRY_RUN', 'true')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment sets DRY_RUN to false' do
      let(:dry_run) { false }

      before do
        stub_env('DRY_RUN', 'false')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment does not define DRY_RUN' do
      let(:dry_run) { false }

      include_examples "call table locker", :lock_writes
    end

    context 'when environment sets VERBOSE to true' do
      let(:verbose) { true }

      before do
        stub_env('VERBOSE', 'true')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment sets VERBOSE to false' do
      let(:verbose) { false }

      before do
        stub_env('VERBOSE', 'false')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment does not define VERBOSE' do
      include_examples "call table locker", :lock_writes
    end
  end

  describe 'unlock_writes' do
    context 'when environment sets DRY_RUN to true' do
      let(:dry_run) { true }

      before do
        stub_env('DRY_RUN', 'true')
      end

      include_examples "call table locker", :unlock_writes
    end

    context 'when environment sets DRY_RUN to false' do
      before do
        stub_env('DRY_RUN', 'false')
      end

      include_examples "call table locker", :unlock_writes
    end

    context 'when environment does not define DRY_RUN' do
      include_examples "call table locker", :unlock_writes
    end

    context 'when environment sets VERBOSE to true' do
      let(:verbose) { true }

      before do
        stub_env('VERBOSE', 'true')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment sets VERBOSE to false' do
      let(:verbose) { false }

      before do
        stub_env('VERBOSE', 'false')
      end

      include_examples "call table locker", :lock_writes
    end

    context 'when environment does not define VERBOSE' do
      include_examples "call table locker", :lock_writes
    end
  end
end
