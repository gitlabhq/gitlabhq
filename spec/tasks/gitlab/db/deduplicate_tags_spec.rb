# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:deduplicate_tags', :silence_stdout, feature_category: :runner_core do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/deduplicate_tags'
  end

  subject(:run_rake) { run_rake_task('gitlab:db:deduplicate_tags') }

  it 'calls execute on DeduplicateCiTags' do
    expect_next_instance_of(
      Gitlab::Database::DeduplicateCiTags, logger: an_instance_of(Logger), dry_run: false
    ) do |service|
      expect(service).to receive(:execute)
    end

    run_rake
  end

  context 'when DRY_RUN is true' do
    before do
      stub_env('DRY_RUN', true)
    end

    it 'calls execute on DeduplicateCiTags with dry_run = true' do
      expect_next_instance_of(
        Gitlab::Database::DeduplicateCiTags, logger: an_instance_of(Logger), dry_run: true
      ) do |service|
        expect(service).to receive(:execute)
      end

      run_rake
    end
  end
end
