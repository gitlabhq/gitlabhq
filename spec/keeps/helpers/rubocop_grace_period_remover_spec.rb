# frozen_string_literal: true

require 'tmpdir'
require 'spec_helper'
require './keeps/helpers/rubocop_grace_period_remover'

RSpec.describe Keeps::Helpers::RubocopGracePeriodRemover, feature_category: :tooling do
  let(:todo_dir) { Dir.mktmpdir }
  let(:grace_period_file) { Pathname(todo_dir).join('grace_period.yml').to_s }
  let(:no_grace_period_file) { Pathname(todo_dir).join('no_grace_period.yml').to_s }
  let(:old_revision) { 'abc123' }

  subject(:remover) { described_class.new }

  before do
    FileUtils.cp('spec/fixtures/keeps/rubocop_grace_period.yml', grace_period_file)
    FileUtils.cp('spec/fixtures/keeps/rubocop_no_grace_period.yml', no_grace_period_file)

    stub_git_grep_files("#{grace_period_file}\n")
    stub_git_rev_list(old_revision)
  end

  after do
    FileUtils.remove_entry(todo_dir)
  end

  def stub_git_grep_files(output)
    allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
      .with('git', 'grep', '--files-with-matches', '--fixed-strings', described_class::KEY_VALUE,
        '--', described_class::TODO_DIR_PATTERN)
      .and_return(output)
  end

  def stub_git_rev_list(revision)
    allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
      .with('git', 'rev-list', '--max-count=1', a_string_starting_with('--before='), 'HEAD')
      .and_return("#{revision}\n")
  end

  def stub_grace_period_present_at(revision, file, present:)
    stub = allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
      .with('git', 'grep', '--quiet', '--fixed-strings', described_class::KEY_VALUE, revision, '--', file)

    if present
      stub.and_return('')
    else
      stub.and_raise(::Gitlab::Housekeeper::Shell::Error, 'not found')
    end
  end

  describe '#remove_overdue' do
    context 'when the grace period was already present MIN_AGE_DAYS ago' do
      before do
        stub_grace_period_present_at(old_revision, grace_period_file, present: true)
      end

      it 'removes the grace period line while preserving other content', :aggregate_failures do
        remover.remove_overdue

        content = File.read(grace_period_file)

        expect(content).not_to include('Details: grace period')
        expect(content).to include('RuboCop/FakeGracePeriodRule')
        expect(content).to include("- 'app/models/fake1.rb'")
        expect(content).to include("- 'app/models/fake2.rb'")
      end
    end

    context 'when the grace period was not present MIN_AGE_DAYS ago' do
      before do
        stub_grace_period_present_at(old_revision, grace_period_file, present: false)
      end

      it 'logs and keeps the grace period line' do
        expect(remover).to receive(:warn).with(/git grep at #{old_revision} for .*: not found/)

        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when the grace period was re-added recently on a pre-existing file' do
      before do
        # The file existed MIN_AGE_DAYS ago, but the grace period line did not (a regeneration run just re-added it
        # because the Exclude list grew), so it must not be stripped in the same pass.
        stub_grace_period_present_at(old_revision, grace_period_file, present: false)
      end

      it 'keeps the freshly re-added grace period line' do
        allow(remover).to receive(:warn)

        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when there is no revision from MIN_AGE_DAYS ago' do
      before do
        stub_git_rev_list('')
      end

      it 'keeps the grace period line' do
        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when git rev-list fails' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'rev-list', '--max-count=1', a_string_starting_with('--before='), 'HEAD')
          .and_raise(::Gitlab::Housekeeper::Shell::Error, 'boom')
      end

      it 'logs the error and keeps the grace period line' do
        expect(remover).to receive(:warn).with(/git rev-list failed: boom/)

        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when no files contain a grace period' do
      before do
        stub_git_grep_files('')
      end

      it 'does not check any revision or modify any file' do
        expect(::Gitlab::Housekeeper::Shell).not_to receive(:execute)
          .with('git', 'rev-list', anything, anything, anything)

        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when git grep finds no files (exits non-zero)' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--files-with-matches', '--fixed-strings', described_class::KEY_VALUE,
            '--', described_class::TODO_DIR_PATTERN)
          .and_raise(::Gitlab::Housekeeper::Shell::Error, 'no match')
      end

      it 'logs the error, treats it as no files, and does nothing' do
        expect(remover).to receive(:warn).with(/git grep found no files with a grace period: no match/)

        remover.remove_overdue

        expect(File.read(grace_period_file)).to include('Details: grace period')
      end
    end

    context 'when computing the cutoff revision', :freeze_time do
      before do
        stub_grace_period_present_at(old_revision, grace_period_file, present: true)
      end

      it 'resolves the revision exactly MIN_AGE_DAYS ago' do
        expected_before = "--before=#{described_class::MIN_AGE_DAYS.days.ago.utc.iso8601}"

        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'rev-list', '--max-count=1', expected_before, 'HEAD')
          .and_return("#{old_revision}\n")

        remover.remove_overdue
      end
    end

    context 'when multiple files contain a grace period' do
      let(:other_grace_period_file) { Pathname(todo_dir).join('other_grace_period.yml').to_s }

      before do
        FileUtils.cp('spec/fixtures/keeps/rubocop_grace_period.yml', other_grace_period_file)
        stub_git_grep_files("#{grace_period_file}\n#{other_grace_period_file}\n")
        stub_grace_period_present_at(old_revision, grace_period_file, present: true)
        stub_grace_period_present_at(old_revision, other_grace_period_file, present: true)
      end

      it 'resolves the cutoff revision only once' do
        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'rev-list', '--max-count=1', a_string_starting_with('--before='), 'HEAD')
          .once
          .and_return("#{old_revision}\n")

        remover.remove_overdue
      end
    end
  end
end
