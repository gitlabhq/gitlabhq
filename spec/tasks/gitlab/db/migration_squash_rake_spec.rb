# frozen_string_literal: true

require 'spec_helper'
require 'git'

RSpec.describe 'gitlab:db:squash', :silence_stdout, feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/migration_squash'
  end

  let(:version) { 'v18.8.0-ee' }
  let(:git) { instance_double(Git::Base, remove: nil, add: nil, show: structure_sql) }
  let(:squasher) { instance_double(Gitlab::Database::Migrations::Squasher, files_to_delete: files_to_delete) }
  let(:files_to_delete) { Array.new(1001) { |i| "db/migrate/#{i}_migration.rb" } }
  let(:todo_files) { [] }
  let(:deleted_paths) { files_to_delete }
  let(:structure_sql) { +"CREATE TABLE users;\n\n" }

  before do
    allow(::Git).to receive(:open).and_return(git)
    allow(Gitlab::Database::Migrations::Squasher).to receive(:new).and_return(squasher)

    allow(main_object).to receive(:`).and_call_original
    allow(main_object).to receive(:`).with(/ls-tree/).and_return('')
    allow(main_object).to receive(:`).with(/diff-filter=D/).and_return(deleted_paths.join("\n"))

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(a_string_starting_with('db/migrate/')).and_return(true)
    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:write).with('db/init_structure.sql', anything)
    allow(File).to receive(:write).with(a_string_starting_with('.rubocop_todo/'), anything)
    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with('.rubocop_todo/**/*.yml').and_return(todo_files)
  end

  describe 'deleting squashed migrations' do
    it 'deletes the files in batches' do
      run_rake_task('gitlab:db:squash', version)

      expect(git).to have_received(:remove).with(files_to_delete[0...500]).ordered
      expect(git).to have_received(:remove).with(files_to_delete[500...1000]).ordered
      expect(git).to have_received(:remove).with(files_to_delete[1000..]).ordered
    end

    context 'when a file is already gone from the working tree' do
      before do
        allow(File).to receive(:exist?).with('db/migrate/0_migration.rb').and_return(false)
      end

      it 'is not passed to git rm' do
        run_rake_task('gitlab:db:squash', version)

        expect(git).to have_received(:remove).at_least(:once)
        expect(git).not_to have_received(:remove).with(array_including('db/migrate/0_migration.rb'))
      end
    end

    context 'when there is nothing to delete' do
      let(:files_to_delete) { [] }

      it 'does not call git rm' do
        run_rake_task('gitlab:db:squash', version)

        expect(git).not_to have_received(:remove)
      end
    end
  end

  describe 'rewriting db/init_structure.sql' do
    let(:structure_sql) do
      +<<~SQL
        CREATE TABLE users;

        CREATE TABLE schema_migrations (version character varying NOT NULL);

        CREATE TABLE ar_internal_metadata (key character varying NOT NULL);

        CREATE TABLE projects;
      SQL
    end

    it 'takes db/structure.sql from the squashed version' do
      run_rake_task('gitlab:db:squash', version)

      expect(git).to have_received(:show).with(version, 'db/structure.sql')
    end

    it 'drops the schema_migrations and ar_internal_metadata tables and stages the file' do
      run_rake_task('gitlab:db:squash', version)

      expect(File).to have_received(:write).with('db/init_structure.sql', <<~SQL)
        CREATE TABLE users;

        CREATE TABLE projects;
      SQL
      expect(git).to have_received(:add).with('db/init_structure.sql')
    end
  end

  describe 'pruning .rubocop_todo/' do
    let(:todo_files) { ['.rubocop_todo/rspec/be_eq.yml'] }
    let(:deleted_paths) { ['db/migrate/1_migration.rb'] }
    let(:todo_content) do
      <<~YAML.chomp
        RSpec/BeEq:
          Exclude:
            - 'db/migrate/1_migration.rb'
            - 'db/migrate/kept_migration.rb'
      YAML
    end

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('.rubocop_todo/rspec/be_eq.yml').and_return(todo_content)
    end

    it 'drops the lines naming deleted files and stages the todo files' do
      run_rake_task('gitlab:db:squash', version)

      expect(File).to have_received(:write).with('.rubocop_todo/rspec/be_eq.yml', <<~YAML)
        RSpec/BeEq:
          Exclude:
            - 'db/migrate/kept_migration.rb'
      YAML
      expect(git).to have_received(:add).with(todo_files)
    end
  end
end
