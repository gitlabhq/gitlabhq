# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'migration_fix_15_11', :reestablished_active_record_base, feature_category: :database do
  let(:db) { ApplicationRecord.connection }
  let(:target_init_schema) { '20220314184009' }
  let(:earlier_init_schema) { '20210101010101' }

  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/db/migration_fix_15_11'
  end

  describe 'migration_fix_15_11' do
    context 'when fix is needed' do
      it 'patches init_schema' do
        db.execute('DELETE FROM schema_migrations')
        db.execute("INSERT INTO schema_migrations (version) VALUES ('#{target_init_schema}')")
        run_rake_task(:migration_fix_15_11)
        result = db.execute('SELECT * FROM schema_migrations')
        expect(result.count).to eq(300)
      end
    end

    context 'when fix is not needed because no migrations have been run' do
      it 'does nothing' do
        db.execute('DELETE FROM schema_migrations')
        run_rake_task(:migration_fix_15_11)
        result = db.execute('SELECT * FROM schema_migrations')
        expect(result.count).to eq(0)
      end
    end

    context 'when fix is not needed because DB has not been initialized' do
      it 'does nothing' do
        db.execute('DROP TABLE schema_migrations')
        expect { run_rake_task(:migration_fix_15_11) }.not_to raise_error
      end
    end

    context 'when fix is not needed because there is an earlier init_schema' do
      it 'does nothing' do
        db.execute('DELETE FROM schema_migrations')
        db.execute("INSERT INTO schema_migrations (version) VALUES ('#{earlier_init_schema}')")
        run_rake_task(:migration_fix_15_11)
        result = db.execute('SELECT * FROM schema_migrations')
        expect(result.pluck('version')).to match_array [earlier_init_schema]
      end
    end

    context 'when fix is not needed because the fix has been run already' do
      it 'does not affect the schema_migrations table' do
        db.execute('DELETE FROM schema_migrations')
        db.execute("INSERT INTO schema_migrations (version) VALUES ('#{target_init_schema}')")
        run_rake_task(:migration_fix_15_11)
        fixed_table = db.execute('SELECT version FROM schema_migrations').pluck('version')
        run_rake_task(:migration_fix_15_11)
        test_fixed_table = db.execute('SELECT version FROM schema_migrations').pluck('version')
        expect(fixed_table).to match_array test_fixed_table
      end
    end
  end
end
