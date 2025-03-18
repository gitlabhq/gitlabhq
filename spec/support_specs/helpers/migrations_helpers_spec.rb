# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrationsHelpers, feature_category: :database do
  include StubENV

  let(:helper_class) do
    Class.new.tap do |klass|
      klass.include described_class
      allow(klass).to receive(:metadata).and_return(metadata)
    end
  end

  let(:metadata) { {} }
  let(:helper) { helper_class.new }

  describe '#active_record_base' do
    it 'returns the main base model' do
      expect(helper.active_record_base).to eq(ActiveRecord::Base)
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'returns the CI base model' do
        expect(helper.active_record_base(database: :ci)).to eq(Ci::ApplicationRecord)
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it 'returns the CI base model with a connection to the main model' do
        model = helper.active_record_base(database: :ci)

        expect(model).to eq(Ci::ApplicationRecord)
        expect(model.connection_specification_name).to eq('ActiveRecord::Base')
      end
    end

    it 'raises ArgumentError for bad database argument' do
      expect { helper.active_record_base(database: :non_existent) }.to raise_error(ArgumentError)
    end
  end

  describe '#table' do
    it 'creates a class based on main base model' do
      klass = helper.table(:projects)
      expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'create a class based on the CI base model' do
        klass = helper.table(:p_ci_builds, database: :ci) { |model| model.primary_key = :id }
        expect(klass.connection_specification_name).to eq('Ci::ApplicationRecord')
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it 'creates a class based on main base model' do
        klass = helper.table(:p_ci_builds, database: :ci) { |model| model.primary_key = :id }
        expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
      end
    end
  end

  describe '#reset_column_information' do
    context 'with a regular ActiveRecord model class' do
      let(:klass) { Project }

      it 'calls reset_column_information' do
        expect(klass).to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end

    context 'with an anonymous class with table name defined' do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = :projects
        end
      end

      it 'calls reset_column_information' do
        expect(klass).to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end

    context 'with an anonymous class with no table name defined' do
      let(:klass) { Class.new(ActiveRecord::Base) }

      it 'does not call reset_column_information' do
        expect(klass).not_to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end
  end

  describe '#finalized_by_version' do
    let(:dictionary_entry) { nil }

    before do
      allow(helper).to receive(:described_class)
      allow(::Gitlab::Utils::BatchedBackgroundMigrationsDictionary).to(
        receive(:entry).and_return(dictionary_entry)
      )
    end

    context 'when no dictionary was found' do
      it { expect(helper.finalized_by_version).to be_nil }
    end

    context 'when finalized_by is a string' do
      let(:dictionary_entry) do
        instance_double(
          ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary,
          finalized_by: '20240104155616'
        )
      end

      it { expect(helper.finalized_by_version).to eq(20240104155616) }
    end
  end

  describe '#migration_out_of_test_window?' do
    before do
      allow(Gitlab::Database).to receive(:min_schema_gitlab_version).and_return(Gitlab::VersionInfo.new(17, 8))
    end

    it 'returns false when RUN_ALL_MIGRATION_TESTS is set' do
      stub_env('RUN_ALL_MIGRATION_TESTS', 'true')

      expect(helper.migration_out_of_test_window?(double)).to be(false)
    end

    context 'with database migration' do
      it 'returns true when the migration milestone is missing' do
        migration_class = Class.new(Gitlab::Database::Migration[2.2])

        expect(helper.migration_out_of_test_window?(migration_class)).to be(true)
      end

      it 'returns true when migration milestone is before min milestone' do
        migration_class = Class.new(Gitlab::Database::Migration[2.2]) do
          milestone '17.7'
        end

        expect(helper.migration_out_of_test_window?(migration_class)).to be(true)
      end

      it 'returns false when migration milestone is equal or after min milestone' do
        migration_class = Class.new(Gitlab::Database::Migration[2.2]) do
          milestone '17.8'
        end

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end
    end

    context 'with background migration' do
      def migration_paths(timestamp)
        [
          Rails.root.join("db/migrate/#{timestamp}_*.rb").to_s,
          Rails.root.join("db/post_migrate/#{timestamp}_*.rb").to_s
        ]
      end

      let(:migration_class) { Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) }

      it 'returns false if the migration is not finalized' do
        allow(helper).to receive(:finalized_by_version).and_return('')

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end

      it 'returns false if the finalizing migration file can not be found' do
        finalized_by = '20240104155616'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by)).and_return([])
        #   File.join(Rails.root, "db/migrate/#{finalized_by}_*.rb"),
        #   File.join(Rails.root, "db/post_migrate/#{finalized_by}_*.rb")
        # ).and_return([])

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end

      it 'returns false if the finalizing migration class name can not be found' do
        finalized_by = '20240104155616'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by))
          .and_return(["spec/fixtures/migrations/db/post_migrate/#{finalized_by}_no_such_file.rb"])

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end

      it 'returns false if the finalizing migration class name can not be constantized' do
        finalized_by = '20240104155616'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by))
          .and_return(["spec/fixtures/migrations/db/post_migrate/#{finalized_by}_no_such_class.rb"])

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end

      it 'returns true if the finalizing migration milestone is missing' do
        finalized_by = '20240104155616'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by))
          .and_return(["spec/fixtures/migrations/db/post_migrate/#{finalized_by}_test_migration_with_no_milestone.rb"])

        expect(helper.migration_out_of_test_window?(migration_class)).to be(true)
      end

      it 'returns true if the finalizing migration milestone is before min milestone' do
        finalized_by = '20240104155617'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by))
          .and_return(
            ["spec/fixtures/migrations/db/post_migrate/#{finalized_by}_test_migration_with_milestone_17_7.rb"]
          )

        expect(helper.migration_out_of_test_window?(migration_class)).to be(true)
      end

      it 'returns false if the finalizing migration milestone is equal or after min milestone' do
        finalized_by = '20240104155618'
        allow(helper).to receive(:finalized_by_version).and_return(finalized_by)

        expect(Dir).to receive(:[]).with(*migration_paths(finalized_by))
          .and_return(
            ["spec/fixtures/migrations/db/post_migrate/#{finalized_by}_test_migration_with_milestone_17_8.rb"]
          )

        expect(helper.migration_out_of_test_window?(migration_class)).to be(false)
      end
    end
  end
end
