# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../tooling/quality/added_tables'

RSpec.describe 'gitlab:seed:coverage_report', :silence_stdout, feature_category: :tooling do
  let(:added_tables) { instance_double(Quality::AddedTables) }

  before do
    Rake.application.rake_require 'tasks/gitlab/seed'
    stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_SHA', nil)
    stub_env('CI_MERGE_REQUEST_DIFF_BASE_SHA', nil)
  end

  def stub_entry_names(names)
    allow(Quality::AddedTables).to receive(:new).and_return(added_tables)
    allow(added_tables).to receive(:entry_names).and_return(names)
  end

  describe 'choosing the base ref' do
    it 'skips the report when no base ref is available' do
      expect { run_rake_task('gitlab:seed:coverage_report') }
        .to output(/No base ref given, skipping the fixture coverage report/).to_stdout
    end

    it 'prefers the target branch tip over the merge base' do
      stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_SHA', 'target-sha')
      stub_env('CI_MERGE_REQUEST_DIFF_BASE_SHA', 'base-sha')
      stub_entry_names([])

      run_rake_task('gitlab:seed:coverage_report')

      expect(Quality::AddedTables).to have_received(:new).with('target-sha')
    end

    it 'falls back to the merge base when the target branch tip is unavailable' do
      stub_env('CI_MERGE_REQUEST_DIFF_BASE_SHA', 'base-sha')
      stub_entry_names([])

      run_rake_task('gitlab:seed:coverage_report')

      expect(Quality::AddedTables).to have_received(:new).with('base-sha')
    end

    it 'prefers an explicit argument over the environment' do
      stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_SHA', 'target-sha')
      stub_entry_names([])

      run_rake_task('gitlab:seed:coverage_report', 'argument-sha')

      expect(Quality::AddedTables).to have_received(:new).with('argument-sha')
    end

    it 'reports that a shallow clone could not resolve the base ref' do
      stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_SHA', 'target-sha')
      allow(Quality::AddedTables).to receive(:new).and_return(added_tables)
      allow(added_tables).to receive(:entry_names)
        .and_raise(Quality::AddedTables::UnreadableBaseRef, 'base ref is not readable')

      expect { run_rake_task('gitlab:seed:coverage_report') }
        .to output(/Cannot report fixture coverage: base ref is not readable/).to_stdout
    end
  end

  describe 'filtering dictionary entries' do
    before do
      stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_SHA', 'target-sha')
    end

    # `db/docs/` also holds views, deleted tables and background migrations, and only tables can
    # carry seed data. `postgres_constraints` is a view, so the dictionary's table scope skips it.
    it 'ignores entries that do not name a table' do
      stub_entry_names(%w[postgres_constraints])

      expect { run_rake_task('gitlab:seed:coverage_report') }
        .to output(/No new tables in this diff, skipping the fixture coverage report/).to_stdout
    end

    it 'reports coverage for an added table' do
      stub_entry_names(%w[projects])

      expect { run_rake_task('gitlab:seed:coverage_report') }
        .to output(/Fixture coverage for 1 newly added table\(s\).*projects:/m).to_stdout
    end

    it 'never fails the job' do
      stub_entry_names(%w[projects])

      expect { run_rake_task('gitlab:seed:coverage_report') }
        .to output(/Report only - this task never fails the job\./).to_stdout
    end
  end
end
