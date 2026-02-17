# frozen_string_literal: true

require 'spec_helper'
require './keeps/squash_migrations'

RSpec.describe Keeps::SquashMigrations, feature_category: :database do
  let(:milestones_helper) { instance_double(Keeps::Helpers::Milestones) }
  let(:current_milestone) { '18.8' }

  subject(:keep) { described_class.new }

  before do
    allow(Keeps::Helpers::Milestones).to receive(:new).and_return(milestones_helper)
    allow(milestones_helper).to receive(:current_milestone).and_return(current_milestone)
  end

  describe 'squash migration validation' do
    subject(:keep) { described_class.new }

    context 'when db/init_structure.sql is modified' do
      before do
        allow(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'diff', 'HEAD', '--name-only', '--diff-filter=AM')
          .and_return("db/init_structure.sql\ndb/migrate/some_file.rb")
      end

      it 'does not raise an error' do
        expect { keep.send(:all_modified_files) }.not_to raise_error
      end
    end

    context 'when db/init_structure.sql is not modified' do
      before do
        allow(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'diff', 'HEAD', '--name-only', '--diff-filter=AM')
          .and_return("db/migrate/some_file.rb")
      end

      it 'raises an error about missing db/init_structure.sql' do
        expect { keep.send(:all_modified_files) }.to raise_error(
          RuntimeError,
          'Squash did not update db/init_structure.sql'
        )
      end
    end
  end

  describe '#each_identified_change' do
    context 'when current minor version is in SCHEDULED_STOPS' do
      let(:current_milestone) { '18.8' }

      it 'yields a change' do
        expect { |b| keep.each_identified_change(&b) }.to yield_with_args(
          have_attributes(
            identifiers: ['SquashMigrations', '18.2']
          )
        )
      end
    end

    context 'when current minor version is not in SCHEDULED_STOPS' do
      let(:current_milestone) { '18.3' }

      it 'does not yield any changes' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end
  end

  describe '#make_change!' do
    let(:change) { Gitlab::Housekeeper::Change.new }
    let(:modified_files) { ['db/init_structure.sql', 'db/migrate/old_migration.rb'] }

    before do
      allow(Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('bundle', 'exec', 'rake', anything)
        .and_return(true)
      allow(Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('git', 'diff', 'HEAD', '--name-only', '--diff-filter=AM')
        .and_return(modified_files.join("\n"))
      allow(keep).to receive(:reviewer).and_return('test-reviewer')
    end

    shared_examples 'squashes migrations correctly' do |_milestone, target_branch|
      it 'creates change with correct attributes', :aggregate_failures do
        actual_change = keep.make_change!(change)

        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(change.title).to eq("Squash database migrations up to origin/#{target_branch}")
        expect(change.labels).to match_array([
          'type::maintenance',
          'database',
          'backend',
          'database::review pending',
          'maintenance::refactor'
        ])
        expect(change.changed_files).to match_array(modified_files)
        expect(change.description).to include(target_branch)
        expect(change.description).to include('db/init_structure.sql')
      end

      it 'runs the squash rake task with correct branch' do
        keep.make_change!(change)

        expect(Gitlab::Housekeeper::Shell).to have_received(:execute)
          .with('bundle', 'exec', 'rake', "gitlab:db:squash[origin/#{target_branch}]")
      end
    end

    context 'when squashing migrations for version 18.8' do
      let(:current_milestone) { '18.8' }

      include_examples 'squashes migrations correctly', '18.8', '18-2-stable-ee'
    end

    context 'when squashing migrations for version 18.2' do
      let(:current_milestone) { '18.2' }

      it_behaves_like 'squashes migrations correctly', '18.2', '17-8-stable-ee'
    end
  end
end
