# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Gitlab::Database::Migrations::Squasher, feature_category: :database do
  let(:git_output) do
    <<~FILES
    db/migrate/misplaced.txt
    db/migrate/20221003041700_init_schema.rb
    db/migrate/20221003041800_foo_migrate.rb
    db/migrate/20221003041900_foo_migrate_two.rb
    db/migrate/20221003042000_add_name_to_widgets.rb
    db/migrate/20221003042200_add_enterprise.rb
    db/post_migrate/20221003042100_post_migrate.rb
    db/post_migrate/20251125231656_finalize_bbm_1.rb
    FILES
  end

  let(:spec_files) do
    [
      'spec/migrations/add_name_to_widgets_spec.rb',
      'spec/migrations/20221003041800_foo_migrate_spec.rb',
      'spec/migrations/foo_migrate_three_spec.rb',
      'spec/migrations/foo_migrate_two_spec.rb',
      'spec/migrations/post_migrate_spec.rb'
    ]
  end

  let(:ee_spec_files) do
    [
      'ee/spec/migrations/add_enterprise_spec.rb'
    ]
  end

  let(:bbm_yml_files) do
    [
      'db/docs/batched_background_migrations/background_migration_1.yml',
      'db/docs/batched_background_migrations/background_migration_2.yml',
      'db/docs/batched_background_migrations/background_migration_3.yml'
    ]
  end

  let(:bbm_1_yml_contents) do
    {
      'migration_job_name' => 'BackgroundMigration1',
      'finalized_by' => '20251125231656'
    }
  end

  let(:bbm_2_yml_contents) do
    {
      'migration_job_name' => 'BackgroundMigration2',
      'finalized_by' => 20251126231656
    }
  end

  let(:bbm_3_yml_contents) do
    {
      'migration_job_name' => 'BackgroundMigration3'
    }
  end

  let(:expected_list) do
    [
      'db/migrate/20221003041800_foo_migrate.rb',
      'db/migrate/20221003041900_foo_migrate_two.rb',
      'db/migrate/20221003042000_add_name_to_widgets.rb',
      'spec/migrations/add_name_to_widgets_spec.rb',
      'spec/migrations/20221003041800_foo_migrate_spec.rb',
      'spec/migrations/foo_migrate_two_spec.rb',
      'db/schema_migrations/20221003041800',
      'db/schema_migrations/20221003041900',
      'db/schema_migrations/20221003042000',
      'db/schema_migrations/20221003042100',
      'db/schema_migrations/20221003042200',
      'db/schema_migrations/20251125231656',
      'db/post_migrate/20221003042100_post_migrate.rb',
      'db/post_migrate/20251125231656_finalize_bbm_1.rb',
      'spec/migrations/post_migrate_spec.rb',
      'ee/spec/migrations/add_enterprise_spec.rb',
      'db/migrate/20221003042200_add_enterprise.rb',
      'db/docs/batched_background_migrations/background_migration_1.yml',
      'lib/gitlab/background_migration/background_migration1.rb',
      'ee/lib/ee/gitlab/background_migration/background_migration1.rb',
      'spec/lib/gitlab/background_migration/background_migration1_spec.rb',
      'ee/spec/lib/ee/gitlab/background_migration/background_migration1_spec.rb'
    ]
  end

  describe "#files_to_delete" do
    before do
      allow(Dir).to receive(:glob).with(Rails.root.join('spec/migrations/**/*.rb')).and_return(spec_files)
      allow(Dir).to receive(:glob).with(Rails.root.join('ee/spec/migrations/**/*.rb')).and_return(ee_spec_files)
      allow(Dir).to receive(:glob).with(Rails.root.join('db/docs/batched_background_migrations/*.yml'))
        .and_return(bbm_yml_files)

      allow(YAML).to receive(:load_file).with(bbm_yml_files[0]).and_return(bbm_1_yml_contents)
      allow(YAML).to receive(:load_file).with(bbm_yml_files[1]).and_return(bbm_2_yml_contents)
      allow(YAML).to receive(:load_file).with(bbm_yml_files[2]).and_return(bbm_3_yml_contents)
    end

    let(:squasher) { described_class.new(git_output) }

    it 'only deletes the files we\'re expecting' do
      expect(squasher.files_to_delete).to match_array expected_list
    end
  end
end
