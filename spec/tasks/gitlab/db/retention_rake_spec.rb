# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:retention namespace rake tasks', :silence_stdout, feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/retention'
  end

  describe 'generate_allowlist' do
    let(:tmp_root) { Pathname.new(Dir.mktmpdir) }
    let(:allowlist_path) { tmp_root.join('spec/support/database/retention-policy-missing-allowlist.yml') }
    let(:data_retention_dir) { tmp_root.join('db/docs/data_retention') }

    # Default to a schema that is eligible so tests that don't care about
    # schema filtering keep working. Contexts that exercise schema filtering
    # override this and pass gitlab_schema explicitly per entry.
    let(:eligible_schema) { Gitlab::Database::RetentionPolicy::ELIGIBLE_SCHEMAS.first }

    let(:fake_entries) do
      %w[projects users deleted_by_rake declared_table].map do |name|
        instance_double(Gitlab::Database::Dictionary::Entry, table_name: name, gitlab_schema: eligible_schema)
      end
    end

    before do
      allowlist_path.dirname.mkpath
      data_retention_dir.mkpath

      allow(Rails).to receive(:root).and_return(tmp_root)
      allow(Gitlab::Database::Dictionary).to receive(:entries).and_return(fake_entries)
    end

    after do
      FileUtils.rm_rf(tmp_root)
    end

    subject(:run_rake) { run_rake_task('gitlab:db:retention:generate_allowlist') }

    context 'when no table declares a retention policy' do
      it 'writes every table into the allowlist, sorted' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path))
          .to eq(%w[declared_table deleted_by_rake projects users])
      end

      it 'includes the header comment block' do
        run_rake

        contents = File.read(allowlist_path)
        expect(contents).to include('# Tables that do not yet declare a retention policy')
        expect(contents).to include('bundle exec rake gitlab:db:retention:generate_allowlist')
      end

      it 'reports how many tables were written' do
        expect { run_rake }
          .to output(%r{Wrote 4 tables to spec/support/database/retention-policy-missing-allowlist\.yml\.}).to_stdout
      end
    end

    context 'when some tables declare a retention policy' do
      before do
        data_retention_dir.join('projects.yml').write("retention_window: 90\n")
        data_retention_dir.join('declared_table.yml').write("retention_window: 30\n")
      end

      it 'omits tables that have a retention policy declaration' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path)).to eq(%w[deleted_by_rake users])
      end

      it 'reports only the tables that were written' do
        expect { run_rake }.to output(/Wrote 2 tables/).to_stdout
      end
    end

    context 'when every table declares a retention policy' do
      before do
        fake_entries.each do |entry|
          data_retention_dir.join("#{entry.table_name}.yml").write("retention_window: 90\n")
        end
      end

      it 'writes an empty allowlist' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path)).to eq([])
      end
    end

    context 'when the Dictionary reports no entries' do
      let(:fake_entries) { [] }

      it 'writes an empty allowlist' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path)).to eq([])
      end
    end

    context 'when the Dictionary reports the same table across multiple connections' do
      # Gitlab::Database::Dictionary.entries returns one entry per database
      # connection, so tables like schema_migrations and ar_internal_metadata
      # appear multiple times. The rake task must deduplicate before writing.
      let(:fake_entries) do
        %w[schema_migrations schema_migrations schema_migrations users users projects].map do |name|
          instance_double(Gitlab::Database::Dictionary::Entry, table_name: name, gitlab_schema: eligible_schema)
        end
      end

      it 'writes each table only once' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path)).to eq(%w[projects schema_migrations users])
      end

      it 'reports the deduplicated count' do
        expect { run_rake }.to output(/Wrote 3 tables/).to_stdout
      end
    end

    context 'when some entries belong to an excluded schema' do
      let(:excluded_schema) { Gitlab::Database::RetentionPolicy::EXCLUDED_SCHEMAS.first }

      let(:fake_entries) do
        [
          instance_double(Gitlab::Database::Dictionary::Entry, table_name: 'projects', gitlab_schema: eligible_schema),
          instance_double(Gitlab::Database::Dictionary::Entry, table_name: 'users', gitlab_schema: eligible_schema),
          instance_double(Gitlab::Database::Dictionary::Entry, table_name: 'geo_only_table',
            gitlab_schema: excluded_schema)
        ]
      end

      it 'omits tables from excluded schemas' do
        run_rake

        expect(YAML.safe_load_file(allowlist_path)).to eq(%w[projects users])
      end
    end
  end
end
