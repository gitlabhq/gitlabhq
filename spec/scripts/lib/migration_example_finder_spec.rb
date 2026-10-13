# frozen_string_literal: true

require 'fast_spec_helper'
require 'fileutils'
require 'tmpdir'

require_relative '../../../scripts/lib/migration_example_finder'

RSpec.describe MigrationExampleFinder, feature_category: :tooling do
  let(:tmpdir) { Dir.mktmpdir }
  let(:root_path) { "#{tmpdir}/" }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  subject(:finder) { described_class.new(root_path) }

  def write(path)
    full = File.join(root_path, path)
    FileUtils.mkdir_p(File.dirname(full))
    FileUtils.touch(full)
  end

  describe '#newest_with_spec' do
    context 'when a migration has a timestamped spec' do
      before do
        write('db/post_migrate/20260101000000_add_widgets.rb')
        write('spec/migrations/20260101000000_add_widgets_spec.rb')
      end

      it 'finds it' do
        migration, spec = finder.newest_with_spec(timestamped: true)

        expect(migration).to eq('db/post_migrate/20260101000000_add_widgets.rb')
        expect(spec).to eq('spec/migrations/20260101000000_add_widgets_spec.rb')
      end

      it 'is not offered for the non-timestamped form' do
        expect(finder.newest_with_spec(timestamped: false)).to be_nil
      end
    end

    context 'when a migration has a non-timestamped spec' do
      before do
        write('db/migrate/20260101000000_add_widgets.rb')
        write('spec/migrations/add_widgets_spec.rb')
      end

      it 'finds it' do
        migration, spec = finder.newest_with_spec(timestamped: false)

        expect(migration).to eq('db/migrate/20260101000000_add_widgets.rb')
        expect(spec).to eq('spec/migrations/add_widgets_spec.rb')
      end

      it 'is not offered for the timestamped form' do
        expect(finder.newest_with_spec(timestamped: true)).to be_nil
      end
    end

    it 'returns nil when no migration has a spec' do
      write('db/migrate/20260101000000_add_widgets.rb')

      expect(finder.newest_with_spec(timestamped: true)).to be_nil
      expect(finder.newest_with_spec(timestamped: false)).to be_nil
    end

    it 'returns nil when there are no migrations at all' do
      expect(finder.newest_with_spec(timestamped: true)).to be_nil
    end

    it 'prefers the newest migration' do
      write('db/post_migrate/20260101000000_older.rb')
      write('spec/migrations/20260101000000_older_spec.rb')
      write('db/post_migrate/20260601000000_newer.rb')
      write('spec/migrations/20260601000000_newer_spec.rb')

      expect(finder.newest_with_spec(timestamped: true).first)
        .to eq('db/post_migrate/20260601000000_newer.rb')
    end

    it 'orders by timestamp across both migration directories' do
      # db/migrate sorts before db/post_migrate by path, so a path-ordered
      # search would wrongly return the older post_migrate entry.
      write('db/migrate/20260601000000_newer.rb')
      write('spec/migrations/20260601000000_newer_spec.rb')
      write('db/post_migrate/20260101000000_older.rb')
      write('spec/migrations/20260101000000_older_spec.rb')

      expect(finder.newest_with_spec(timestamped: true).first)
        .to eq('db/migrate/20260601000000_newer.rb')
    end

    it 'skips a newer migration that has no spec' do
      write('db/post_migrate/20260601000000_no_spec.rb')
      write('db/post_migrate/20260101000000_has_spec.rb')
      write('spec/migrations/20260101000000_has_spec_spec.rb')

      expect(finder.newest_with_spec(timestamped: true).first)
        .to eq('db/post_migrate/20260101000000_has_spec.rb')
    end
  end
end
