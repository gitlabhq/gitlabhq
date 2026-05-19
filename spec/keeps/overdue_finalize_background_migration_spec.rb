# frozen_string_literal: true

require 'spec_helper'
require './keeps/overdue_finalize_background_migration'

MigrationRecord = Struct.new(:id, :finished_at, :updated_at, :gitlab_schema) do
  def finished?
    true
  end
end

RSpec.describe Keeps::OverdueFinalizeBackgroundMigration, feature_category: :tooling do
  subject(:keep) { described_class.new }

  describe '#each_identified_change' do
    let(:postgres_ai) { instance_double(Keeps::Helpers::PostgresAi) }
    let(:migration_yaml) do
      {
        'milestone' => '16.0',
        'migration_job_name' => 'SomeBackgroundMigration',
        'finalized_by' => nil,
        'feature_category' => 'database'
      }
    end

    let(:yaml_file) { 'db/docs/batched_background_migrations/some_migration.yml' }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: '2023-01-01', updated_at: '2023-01-01', gitlab_schema: 'gitlab_main')
    end

    let(:last_migration_file) { 'db/post_migrate/20230101000000_queue_some_background_migration.rb' }

    before do
      allow(keep).to receive(:before_cuttoff_milestone?).with('16.0').and_return(true)
      allow(keep).to receive_messages(
        batched_background_migrations: { yaml_file => migration_yaml },
        migration_finalized?: false,
        fetch_migration_status: migration_record,
        last_migration_for_job: last_migration_file
      )
    end

    it 'yields a change with correct identifiers and context' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.size).to eq(1)
      change = changes.first
      expect(change).to be_a(::Gitlab::Housekeeper::Change)
      expect(change.identifiers).to eq(%w[OverdueFinalizeBackgroundMigration SomeBackgroundMigration])
      expect(change.context[:job_name]).to eq('SomeBackgroundMigration')
      expect(change.context[:migration_record]).to eq(migration_record)
      expect(change.context[:last_migration_file]).to eq(last_migration_file)
      expect(change.context[:migration_yaml_file]).to eq(yaml_file)
    end

    context 'when migration is before cutoff but already finalized' do
      before do
        allow(keep).to receive(:migration_finalized?).and_return(true)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when migration is not before cutoff milestone' do
      before do
        allow(keep).to receive(:before_cuttoff_milestone?).with('16.0').and_return(false)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when fetch_migration_status returns nil' do
      before do
        allow(keep).to receive(:fetch_migration_status).and_return(nil)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when last_migration_for_job returns nil' do
      before do
        allow(keep).to receive(:last_migration_for_job).and_return(nil)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end
  end

  describe '#make_change!' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:job_name) { 'TestBackgroundMigration' }
    let(:migration_yaml_file) { tmp_dir.join('migration.yml').to_s }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: '2023-01-01', updated_at: '2023-01-01', gitlab_schema: 'gitlab_main')
    end

    let(:last_migration_file) { 'db/post_migrate/20230101000000_queue_test_background_migration.rb' }
    let(:migration) do
      { 'feature_category' => 'database', 'introduced_by_url' => nil, 'milestone' => '16.0' }
    end

    let(:change) do
      ::Gitlab::Housekeeper::Change.new.tap do |c|
        c.identifiers = ['OverdueFinalizeBackgroundMigration', job_name]
        c.context = {
          migration: migration,
          migration_record: migration_record,
          job_name: job_name,
          last_migration_file: last_migration_file,
          migration_yaml_file: migration_yaml_file
        }
      end
    end

    let(:queue_method_node) { instance_double(RuboCop::AST::SendNode) }
    let(:generator) { instance_double(PostDeploymentMigration::PostDeploymentMigrationGenerator) }
    let(:generated_migration_file) { tmp_dir.join('db/post_migrate/20230601000000_finalize_hk_test.rb').to_s }

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    before do
      File.write(migration_yaml_file, YAML.dump(migration))

      allow(keep).to receive(:initialize_change_details)
      allow(keep).to receive_messages(find_queue_method_node: queue_method_node,
        unique_migration_name: 'FinalizeHKTestBackgroundMigration')
      allow(PostDeploymentMigration::PostDeploymentMigrationGenerator)
        .to receive(:source_root)
      allow(PostDeploymentMigration::PostDeploymentMigrationGenerator)
        .to receive(:new).and_return(generator)
      allow(generator).to receive_messages(invoke_all: [generated_migration_file], migration_number: '20230601000000')
      allow(keep).to receive(:add_ensure_call_to_migration)
      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(anything, 'w').and_yield(StringIO.new)
    end

    it 'returns a change with changed_files', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result).to be_a(::Gitlab::Housekeeper::Change)
      expect(result.changed_files).to include(generated_migration_file)
      expect(result.changed_files).to include(migration_yaml_file)
    end

    it 'calls initialize_change_details' do
      keep.make_change!(change)

      expect(keep).to have_received(:initialize_change_details)
        .with(change, migration, migration_record, job_name, last_migration_file)
    end

    it 'generates migration and runs rubocop autocorrect' do
      keep.make_change!(change)

      expect(keep).to have_received(:add_ensure_call_to_migration)
        .with(generated_migration_file, queue_method_node, job_name, migration_record)
      expect(::Gitlab::Housekeeper::Shell).to have_received(:rubocop_autocorrect)
        .with(generated_migration_file)
    end
  end

  describe '#add_finalized_by_to_yaml' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:yaml_file) { tmp_dir.join('migration.yml').to_s }

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it 'writes finalized_by to the yaml file' do
      File.write(yaml_file, YAML.dump({ 'migration_job_name' => 'TestMigration', 'milestone' => '16.0' }))

      keep.send(:add_finalized_by_to_yaml, yaml_file, '20230601000000')

      content = YAML.load_file(yaml_file)
      expect(content['finalized_by']).to eq('20230601000000')
      expect(content['migration_job_name']).to eq('TestMigration')
    end
  end

  describe '#last_migration_for_job' do
    let(:job_name) { 'TestBackgroundMigration' }

    subject(:result) { keep.send(:last_migration_for_job, job_name) }

    context 'when matching files exist with queue_batched_background_migration' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', "MIGRATION = .#{job_name}.")
          .and_return("db/post_migrate/20230101_queue_test.rb\ndb/post_migrate/20230201_queue_test2.rb\n")

        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('db/post_migrate/20230101_queue_test.rb')
          .and_return('queue_batched_background_migration')
        allow(File).to receive(:read).with('db/post_migrate/20230201_queue_test2.rb')
          .and_return('queue_batched_background_migration')
      end

      it 'returns the latest file' do
        expect(result).to eq('db/post_migrate/20230201_queue_test2.rb')
      end
    end

    context 'when no files contain queue_batched_background_migration' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', "MIGRATION = .#{job_name}.")
          .and_return("db/post_migrate/20230101_some_file.rb\n")

        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('db/post_migrate/20230101_some_file.rb')
          .and_return('ensure_batched_background_migration_is_finished')
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when git grep finds no results' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', "MIGRATION = .#{job_name}.")
          .and_raise(::Gitlab::Housekeeper::Shell::Error)
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#strip_comments' do
    it 'removes comment lines except the first line' do
      code = "# frozen_string_literal: true\n# this is a comment\nclass Foo\nend\n"
      result = keep.send(:strip_comments, code)

      expect(result).to eq("# frozen_string_literal: true\nclass Foo\nend\n")
    end

    it 'preserves non-comment lines' do
      code = "line1\nline2\nline3\n"
      result = keep.send(:strip_comments, code)

      expect(result).to eq("line1\nline2\nline3\n")
    end

    it 'preserves the first line even if it is a comment' do
      code = "# first line comment\n# second line comment\ncode\n"
      result = keep.send(:strip_comments, code)

      expect(result).to eq("# first line comment\ncode\n")
    end
  end

  describe '#fetch_migration_status' do
    let(:postgres_ai) { instance_double(Keeps::Helpers::PostgresAi) }
    let(:job_name) { 'TestBackgroundMigration' }

    before do
      allow(keep).to receive(:postgres_ai).and_return(postgres_ai)
    end

    context 'when exactly one result is returned and migration is finished' do
      let(:record_data) { { 'id' => 1, 'status' => 3, 'gitlab_schema' => 'gitlab_main' } }

      before do
        result = [record_data]
        allow(result).to receive(:count).and_return(1)
        allow(postgres_ai).to receive(:fetch_background_migration_status).with(job_name).and_return(result)
      end

      it 'returns the migration model' do
        migration_model = keep.send(:fetch_migration_status, job_name)

        expect(migration_model).to be_a(::Gitlab::Database::BackgroundMigration::BatchedMigration)
        expect(migration_model).to be_finished
      end
    end

    context 'when no results are returned' do
      before do
        result = []
        allow(result).to receive(:count).and_return(0)
        allow(postgres_ai).to receive(:fetch_background_migration_status).with(job_name).and_return(result)
      end

      it 'returns nil' do
        expect(keep.send(:fetch_migration_status, job_name)).to be_nil
      end
    end

    context 'when multiple results are returned' do
      before do
        result = [{ 'id' => 1 }, { 'id' => 2 }]
        allow(result).to receive(:count).and_return(2)
        allow(postgres_ai).to receive(:fetch_background_migration_status).with(job_name).and_return(result)
      end

      it 'returns nil' do
        expect(keep.send(:fetch_migration_status, job_name)).to be_nil
      end
    end

    context 'when migration is not finished' do
      let(:record_data) { { 'id' => 1, 'status' => 0, 'gitlab_schema' => 'gitlab_main' } }

      before do
        result = [record_data]
        allow(result).to receive(:count).and_return(1)
        allow(postgres_ai).to receive(:fetch_background_migration_status).with(job_name).and_return(result)
      end

      it 'returns nil' do
        expect(keep.send(:fetch_migration_status, job_name)).to be_nil
      end
    end
  end

  describe '#migration_finalized?' do
    let(:job_name) { 'TestBackgroundMigration' }

    context 'when migration has finalized_by set' do
      let(:migration) { { 'finalized_by' => '20230601000000' } }

      it 'returns true' do
        expect(keep.send(:migration_finalized?, migration, job_name)).to be true
      end
    end

    context 'when migration has no finalized_by and ensure call exists' do
      let(:migration) { { 'finalized_by' => nil } }

      before do
        allow(keep).to receive(:`).with("git grep --name-only \"#{job_name}\"")
          .and_return("db/post_migrate/20230601_finalize.rb\n")
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('db/post_migrate/20230601_finalize.rb')
          .and_return('ensure_batched_background_migration_is_finished')
      end

      it 'returns true' do
        expect(keep.send(:migration_finalized?, migration, job_name)).to be true
      end
    end

    context 'when migration has no finalized_by and no ensure call exists' do
      let(:migration) { { 'finalized_by' => nil } }

      before do
        allow(keep).to receive(:`).with("git grep --name-only \"#{job_name}\"")
          .and_return("db/post_migrate/20230101_queue.rb\n")
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('db/post_migrate/20230101_queue.rb')
          .and_return('queue_batched_background_migration')
      end

      it 'returns false' do
        expect(keep.send(:migration_finalized?, migration, job_name)).to be false
      end
    end
  end

  describe '#before_cuttoff_milestone?' do
    before do
      allow(::Gitlab::Database).to receive(:min_schema_gitlab_version).and_return('16.7')
    end

    context 'when milestone is before cutoff' do
      it 'returns true' do
        expect(keep.send(:before_cuttoff_milestone?, '16.6')).to be true
      end
    end

    context 'when milestone equals cutoff' do
      it 'returns true' do
        expect(keep.send(:before_cuttoff_milestone?, '16.7')).to be true
      end
    end

    context 'when milestone is after cutoff' do
      it 'returns false' do
        expect(keep.send(:before_cuttoff_milestone?, '16.8')).to be false
      end
    end
  end

  describe '#batched_background_migrations' do
    let(:yaml_file1) { 'db/docs/batched_background_migrations/migration_a.yml' }
    let(:yaml_file2) { 'db/docs/batched_background_migrations/migration_b.yml' }
    let(:migration_a) { { 'milestone' => '16.5', 'migration_job_name' => 'MigrationA' } }
    let(:migration_b) { { 'milestone' => '16.3', 'migration_job_name' => 'MigrationB' } }

    before do
      allow(keep).to receive(:all_batched_background_migration_files).and_return([yaml_file1, yaml_file2])
      allow(YAML).to receive(:load_file).with(yaml_file1).and_return(migration_a)
      allow(YAML).to receive(:load_file).with(yaml_file2).and_return(migration_b)
    end

    it 'returns migrations sorted by milestone' do
      result = keep.send(:batched_background_migrations)

      expect(result.map(&:last)).to eq([migration_b, migration_a])
    end
  end

  describe '#all_batched_background_migration_files' do
    it 'returns yml files from the batched_background_migrations directory' do
      allow(Dir).to receive(:glob).with('db/docs/batched_background_migrations/*.yml').and_return(
        ['db/docs/batched_background_migrations/test.yml']
      )

      expect(keep.send(:all_batched_background_migration_files))
        .to eq(['db/docs/batched_background_migrations/test.yml'])
    end
  end

  describe '#migration_code_present?' do
    context 'when migration code exists in CE' do
      before do
        allow(File).to receive(:exist?)
          .with(Rails.root.join("lib/gitlab/background_migration/test_migration.rb"))
          .and_return(true)
      end

      it 'returns true' do
        expect(keep.send(:migration_code_present?, 'TestMigration')).to be true
      end
    end

    context 'when migration code exists in EE' do
      before do
        allow(File).to receive(:exist?)
          .with(Rails.root.join("lib/gitlab/background_migration/test_migration.rb"))
          .and_return(false)
        allow(File).to receive(:exist?)
          .with(Rails.root.join("ee/lib/ee/gitlab/background_migration/test_migration.rb"))
          .and_return(true)
      end

      it 'returns true' do
        expect(keep.send(:migration_code_present?, 'TestMigration')).to be true
      end
    end

    context 'when migration code does not exist' do
      before do
        allow(File).to receive(:exist?)
          .with(Rails.root.join("lib/gitlab/background_migration/test_migration.rb"))
          .and_return(false)
        allow(File).to receive(:exist?)
          .with(Rails.root.join("ee/lib/ee/gitlab/background_migration/test_migration.rb"))
          .and_return(false)
      end

      it 'returns false' do
        expect(keep.send(:migration_code_present?, 'TestMigration')).to be false
      end
    end
  end

  describe '#find_queue_method_node' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:migration_file) { tmp_dir.join('queue_migration.rb').to_s }

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it 'returns the queue_batched_background_migration send node' do
      File.write(migration_file, <<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      node = keep.send(:find_queue_method_node, migration_file)

      expect(node).to be_a(RuboCop::AST::SendNode)
      expect(node.method_name).to eq(:queue_batched_background_migration)
    end
  end

  describe '#add_ensure_call_to_migration' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:migration_file) { tmp_dir.join('finalize_migration.rb').to_s }
    let(:queue_migration_file) { tmp_dir.join('queue_migration.rb').to_s }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: '2023-01-01', updated_at: '2023-01-01', gitlab_schema: 'gitlab_main')
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it 'replaces the up method with ensure_batched_background_migration_is_finished call' do
      File.write(migration_file, <<~RUBY)
        # frozen_string_literal: true
        class FinalizeHKTestMigration < Gitlab::Database::Migration[2.2]
          def up
            # placeholder
          end

          def down; end
        end
      RUBY

      File.write(queue_migration_file, <<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      queue_node = keep.send(:find_queue_method_node, queue_migration_file)
      keep.send(:add_ensure_call_to_migration, migration_file, queue_node, 'TestMigration', migration_record)

      content = File.read(migration_file)
      expect(content).to include('ensure_batched_background_migration_is_finished')
      expect(content).to include("job_class_name: 'TestMigration'")
      expect(content).to include('table_name: :users')
      expect(content).to include('column_name: :id')
      expect(content).to include('disable_ddl_transaction!')
      expect(content).to include('restrict_gitlab_migration gitlab_schema: :gitlab_main')
    end

    it 'includes job_arguments when present in the queue call' do
      File.write(migration_file, <<~RUBY)
        # frozen_string_literal: true
        class FinalizeHKTestMigration < Gitlab::Database::Migration[2.2]
          def up
            # placeholder
          end

          def down; end
        end
      RUBY

      File.write(queue_migration_file, <<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              :email,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      queue_node = keep.send(:find_queue_method_node, queue_migration_file)
      keep.send(:add_ensure_call_to_migration, migration_file, queue_node, 'TestMigration', migration_record)

      content = File.read(migration_file)
      expect(content).to include('job_arguments: [:email]')
    end
  end

  describe '#postgres_ai' do
    it 'memoizes the PostgresAi instance' do
      postgres_ai_instance = instance_double(Keeps::Helpers::PostgresAi)
      allow(Keeps::Helpers::PostgresAi).to receive(:new).once.and_return(postgres_ai_instance)

      expect(keep.send(:postgres_ai)).to eq(postgres_ai_instance)
      expect(keep.send(:postgres_ai)).to eq(postgres_ai_instance)
    end
  end

  describe '#initialize_change_details' do
    let(:migration) { { 'feature_category' => 'shared', 'introduced_by_url' => introduced_by_url } }
    let(:feature_category) { migration['feature_category'] }
    let(:introduced_by_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:groups_helper) { instance_double(::Keeps::Helpers::Groups) }
    let(:reviewer_roulette) { instance_double(::Keeps::Helpers::ReviewerRoulette) }
    let(:identifiers) { [described_class.new.class.name.demodulize, job_name] }

    subject(:change) do
      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = identifiers
      keep.send(:initialize_change_details, change, migration, migration_record, job_name, last_migration_file)
      change
    end

    before do
      allow(groups_helper).to receive(:labels_for_feature_category)
        .with(feature_category)
        .and_return([])

      allow(reviewer_roulette).to receive(:random_reviewer_for)
        .with('maintainer::database', identifiers: identifiers)
        .and_return("random-engineer")

      allow(Keeps::Helpers::Groups).to receive(:instance).and_return(groups_helper)
      allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(reviewer_roulette)
      allow(keep).to receive(:assignees_from_introduced_by_mr)
                       .with(introduced_by_url)
                       .and_return(['original-author'])
    end

    it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
      expect(change).to be_a(::Gitlab::Housekeeper::Change)
      expect(change.title).to eq("Finalize BBM #{job_name}")
      expect(change.identifiers).to eq(identifiers)
      expect(change.labels).to eq(['maintenance::removal'])
      expect(change.reviewers).to eq(['random-engineer'])
      expect(change.assignees).to eq(['original-author'])
    end
  end

  describe '#change_description' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:chatops_command) { %r{/chatops gitlab run batched_background_migrations status \d+ --database main} }

    subject(:description) { keep.change_description(migration_record, job_name, last_migration_file) }

    context 'when migration code is present' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(true)
      end

      it 'does not contain a warning' do
        expect(description).not_to match(/^### Warning/)
      end

      it 'contains the database name' do
        expect(description).to match(chatops_command)
      end
    end

    context 'when migration code is absent' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(false)
      end

      it 'does contain a warning' do
        expect(description).to match(/^### Warning/)
      end
    end

    context 'when finished_at is nil' do
      let(:migration_record) do
        MigrationRecord.new(id: 1, finished_at: nil, updated_at: '2023-06-15 10:00:00', gitlab_schema: 'gitlab_main')
      end

      before do
        allow(keep).to receive(:migration_code_present?).and_return(true)
      end

      it 'falls back to updated_at in the description' do
        expect(description).to include('2023-06-15 10:00:00')
      end
    end
  end

  describe '#truncate_migration_name' do
    let(:migration_name) { 'FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationNameThatIsLongerThanLimit' }

    subject(:truncated_name) { keep.truncate_migration_name(migration_name) }

    it 'returns truncated name' do
      expect(truncated_name).to eq('FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationName51841')
    end

    context 'when name is short enough' do
      let(:migration_name) { 'FinalizeHKSomeShortMigrationName' }

      it 'returns the name' do
        expect(truncated_name).to eq(migration_name)
      end
    end
  end

  describe '#unique_migration_name' do
    let(:migration_name) { 'FinalizeHKSomeShortMigrationName' }

    subject(:unique_name) { keep.send(:unique_migration_name, migration_name) }

    context 'when no existing migration with the same name exists' do
      it 'returns the original truncated name' do
        expect(unique_name).to eq(keep.truncate_migration_name(migration_name))
      end
    end

    context 'when an existing migration with the same name exists' do
      before do
        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name(migration_name).underscore}.rb")
          .and_return(['db/post_migrate/20260119233211_finalize_hk_some_short_migration_name.rb'])

        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name("#{migration_name}2").underscore}.rb")
          .and_return([])
      end

      it 'appends a suffix to generate a unique name' do
        expect(unique_name).to eq(keep.truncate_migration_name("#{migration_name}2"))
      end
    end

    context 'when multiple existing migrations with the same name exist' do
      before do
        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name(migration_name).underscore}.rb")
          .and_return(['db/post_migrate/20260119233211_finalize_hk_some_short_migration_name.rb'])

        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name("#{migration_name}2").underscore}.rb")
          .and_return(['db/post_migrate/20260219233211_finalize_hk_some_short_migration_name2.rb'])

        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name("#{migration_name}3").underscore}.rb")
          .and_return([])
      end

      it 'increments the suffix until a unique name is found' do
        expect(unique_name).to eq(keep.truncate_migration_name("#{migration_name}3"))
      end
    end

    context 'when all suffixes up to the limit are taken' do
      before do
        allow(Dir).to receive(:glob)
          .with("db/post_migrate/*_#{keep.truncate_migration_name(migration_name).underscore}.rb")
          .and_return(["db/post_migrate/20260119233211_existing.rb"])

        (2..5).each do |i|
          allow(Dir).to receive(:glob)
            .with("db/post_migrate/*_#{keep.truncate_migration_name("#{migration_name}#{i}").underscore}.rb")
            .and_return(["db/post_migrate/2026011923321#{i}_existing.rb"])
        end
      end

      it 'raises an error' do
        expect { unique_name }.to raise_error(RuntimeError, /Could not find unique migration name/)
      end
    end
  end

  describe '#should_push_code?' do
    using RSpec::Parameterized::TableSyntax

    let(:change) { instance_double(::Gitlab::Housekeeper::Change) }
    let(:outdated_migration_checker) do
      instance_double(Keeps::OverdueFinalizeBackgroundMigrations::OutdatedMigrationChecker)
    end

    before do
      allow(change).to receive_messages(
        identifiers: %w[OverdueFinalizeBackgroundMigration TestMigration],
        has_conflicts: false
      )
      allow(keep).to receive(:outdated_migration_checker).and_return(outdated_migration_checker)
    end

    where(:already_approved, :push_when_approved, :code_update_required, :timestamp_outdated, :expected_result) do
      # When timestamp is outdated, always push regardless of other conditions
      true  | false | false | true | true
      true  | false | true  | true | true
      false | false | false | true | true

      # When timestamp is not outdated, fall back to base Keep behavior
      true  | false | true  | false | false
      true  | false | false | false | false
      true  | true  | true  | false | true
      true  | true  | false | false | false
      false | false | true  | false | true
      false | false | false | false | false
    end

    with_them do
      it 'determines if we should push' do
        allow(change).to receive(:already_approved?).and_return(already_approved)
        allow(change).to receive(:update_required?).with(:code).and_return(code_update_required)
        allow(outdated_migration_checker).to receive(:existing_migration_timestamp_outdated?)
                                         .with(change.identifiers).and_return(timestamp_outdated)

        expect(keep.should_push_code?(change, push_when_approved)).to eq(expected_result)
      end
    end
  end

  describe '#outdated_migration_checker' do
    it 'returns an OutdatedMigrationChecker instance' do
      expect(keep.outdated_migration_checker)
        .to be_a(Keeps::OverdueFinalizeBackgroundMigrations::OutdatedMigrationChecker)
    end

    it 'memoizes the checker' do
      checker = keep.outdated_migration_checker
      expect(keep.outdated_migration_checker).to be(checker)
    end
  end

  describe '#database_name' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: gitlab_schema)
    end

    subject(:database_name) { keep.database_name(migration_record) }

    context 'when schema is gitlab_main_org' do
      let(:gitlab_schema) { 'gitlab_main_org' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when schema is gitlab_main' do
      let(:gitlab_schema) { 'gitlab_main' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when using multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'when schema is gitlab_ci' do
        let(:gitlab_schema) { 'gitlab_ci' }

        it 'returns the database name' do
          expect(database_name).to eq('ci')
        end
      end
    end
  end

  describe '#assignees_from_introduced_by_mr' do
    subject(:assignees) { keep.send(:assignees_from_introduced_by_mr, introduced_by_url) }

    context 'when introduced_by_url is nil' do
      let(:introduced_by_url) { nil }

      it 'returns nil' do
        expect(assignees).to be_nil
      end
    end

    context 'when introduced_by_url is present' do
      let(:introduced_by_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
      let(:merge_request_response) do
        {
          assignees: [
            { username: 'user1' },
            { username: 'user2' }
          ]
        }
      end

      before do
        allow(keep).to receive(:get_merge_request)
                         .with(introduced_by_url)
                         .and_return(merge_request_response)
      end

      it 'returns the assignee usernames' do
        expect(assignees).to eq(%w[user1 user2])
      end

      context 'when merge request has no assignees' do
        let(:merge_request_response) { { assignees: nil } }

        it 'returns nil' do
          expect(assignees).to be_nil
        end
      end

      context 'when get_merge_request returns nil' do
        before do
          allow(keep).to receive(:get_merge_request)
                           .with(introduced_by_url)
                           .and_return(nil)
        end

        it 'returns nil' do
          expect(assignees).to be_nil
        end
      end
    end
  end

  describe '#get_merge_request' do
    subject(:merge_request) { keep.send(:get_merge_request, merge_request_url) }

    context 'when URL does not match the expected pattern' do
      let(:merge_request_url) { 'https://example.com/invalid/url' }

      it 'returns nil' do
        expect(merge_request).to be_nil
      end
    end

    context 'when URL matches the expected pattern' do
      let(:merge_request_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345' }
      let(:api_url) { 'https://gitlab.com/api/v4/projects/278964/merge_requests/12345' }
      let(:response_body) do
        {
          id: 12345,
          iid: 12345,
          assignees: [{ username: 'user1' }]
        }.to_json
      end

      let(:response) { instance_double(HTTParty::Response, success?: true, body: response_body) }

      before do
        allow(Gitlab::HTTP_V2).to receive(:try_get)
                                    .with(api_url)
                                    .and_return(response)
      end

      it 'returns the parsed merge request data' do
        expect(merge_request).to eq({
          id: 12345,
          iid: 12345,
          assignees: [{ username: 'user1' }]
        })
      end

      context 'when the API request fails' do
        let(:response) { instance_double(HTTParty::Response, success?: false, code: 404, body: 'Not found') }

        it 'returns nil' do
          expect(merge_request).to be_nil
        end
      end
    end
  end
end
