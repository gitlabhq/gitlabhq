# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:app namespace rake task', :delete do
  let(:enable_registry) { true }
  let(:backup_tasks) { %w{db repo uploads builds artifacts pages lfs terraform_state registry packages} }
  let(:backup_types) { %w{db repositories uploads builds artifacts pages lfs terraform_state registry packages} }

  def tars_glob
    Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
  end

  def backup_tar
    tars_glob.first
  end

  def backup_files
    %w(backup_information.yml artifacts.tar.gz builds.tar.gz lfs.tar.gz terraform_state.tar.gz pages.tar.gz packages.tar.gz)
  end

  def backup_directories
    %w(db repositories)
  end

  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/backup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/gitlab/db'
    Rake.application.rake_require 'tasks/cache'
  end

  before do
    stub_env('force', 'yes')
    FileUtils.rm(tars_glob, force: true)
    FileUtils.rm(backup_files, force: true)
    FileUtils.rm_rf(backup_directories, secure: true)
    FileUtils.mkdir_p('tmp/tests/public/uploads')
    reenable_backup_sub_tasks
    stub_container_registry_config(enabled: enable_registry)
  end

  after do
    FileUtils.rm(tars_glob, force: true)
    FileUtils.rm(backup_files, force: true)
    FileUtils.rm_rf(backup_directories, secure: true)
    FileUtils.rm_rf('tmp/tests/public/uploads', secure: true)
  end

  def reenable_backup_sub_tasks
    backup_tasks.each do |subtask|
      Rake::Task["gitlab:backup:#{subtask}:create"].reenable
    end
  end

  describe 'backup_restore' do
    context 'gitlab version' do
      before do
        allow(Dir).to receive(:glob).and_return(['1_gitlab_backup.tar'])
        allow(File).to receive(:exist?).and_return(true)
        allow(Kernel).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:cp_r).and_return(true)
        allow(FileUtils).to receive(:mv).and_return(true)
        allow(Rake::Task["gitlab:shell:setup"])
          .to receive(:invoke).and_return(true)
      end

      let(:gitlab_version) { Gitlab::VERSION }

      context 'restore with matching gitlab version' do
        before do
          allow(YAML).to receive(:load_file)
            .and_return({ gitlab_version: gitlab_version })
          expect_next_instance_of(::Backup::Manager) do |instance|
            backup_types.each do |subtask|
              expect(instance).to receive(:run_restore_task).with(subtask).ordered
            end
            expect(instance).not_to receive(:run_restore_task)
          end
          expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)
        end

        it 'invokes restoration on match' do
          expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process
        end
      end
    end

    context 'when the restore directory is not empty' do
      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,terraform_state,registry')

        create(:project, :repository)
      end

      it 'removes stale data' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        excluded_project = create(:project, :repository, name: 'mepmep')

        expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process

        raw_repo = excluded_project.repository.raw

        # The restore will not find the repository in the backup, but will create
        # an empty one in its place
        expect(raw_repo.empty?).to be(true)
      end
    end

    context 'when the backup is restored' do
      let!(:included_project) { create(:project, :repository) }
      let!(:original_checksum) { included_project.repository.checksum }

      before do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        backup_tar = Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar')).last
        allow(Dir).to receive(:glob).and_return([backup_tar])
        allow(File).to receive(:exist?).and_return(true)
        allow(Kernel).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:cp_r).and_return(true)
        allow(FileUtils).to receive(:mv).and_return(true)
        allow(YAML).to receive(:load_file)
          .and_return({ gitlab_version: Gitlab::VERSION })

        expect_next_instance_of(::Backup::Manager) do |instance|
          backup_types.each do |subtask|
            expect(instance).to receive(:run_restore_task).with(subtask).ordered
          end
          expect(instance).not_to receive(:run_restore_task)
        end

        expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)
      end

      it 'restores the data' do
        expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process

        raw_repo = included_project.repository.raw

        expect(raw_repo.empty?).to be(false)
        expect(included_project.repository.checksum).to eq(original_checksum)
      end
    end
  end
  # backup_restore task

  describe 'backup' do
    before do
      # This reconnect makes our project fixture disappear, breaking the restore. Stub it out.
      allow(ActiveRecord::Base.connection).to receive(:reconnect!)
    end

    let!(:project) { create(:project, :repository) }

    describe 'backup creation and deletion using custom_hooks' do
      let(:user_backup_path) { "repositories/#{project.disk_path}" }

      before do
        stub_env('SKIP', 'db')
        path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          File.join(project.repository.path_to_repo, 'custom_hooks')
        end
        FileUtils.mkdir_p(path)
        FileUtils.touch(File.join(path, "dummy.txt"))
      end

      context 'project uses custom_hooks and successfully creates backup' do
        it 'creates custom_hooks.tar and project bundle' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(%W{tar -tvf #{backup_tar}})

          expect(exit_status).to eq(0)
          expect(tar_contents).to match(user_backup_path)
          expect(tar_contents).to match("#{user_backup_path}/.+/001.custom_hooks.tar")
          expect(tar_contents).to match("#{user_backup_path}/.+/001.bundle")
        end

        it 'restores files correctly' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process
          expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process

          repo_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path
          end
          expect(Dir.entries(File.join(repo_path, 'custom_hooks'))).to include("dummy.txt")
        end
      end

      context 'specific backup tasks' do
        it 'prints a progress message to stdout' do
          backup_tasks.each do |task|
            expect { run_rake_task("gitlab:backup:#{task}:create") }.to output(/Dumping /).to_stdout_from_any_process
          end
        end

        it 'logs the progress to log file' do
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping database ... [SKIPPED]")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping repositories ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping repositories ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping uploads ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping uploads ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping builds ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping builds ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping artifacts ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping artifacts ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping pages ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping pages ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping lfs objects ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping lfs objects ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping terraform states ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping terraform states ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping container registry images ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping container registry images ... done")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping packages ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping packages ... done")

          backup_tasks.each do |task|
            run_rake_task("gitlab:backup:#{task}:create")
          end
        end
      end
    end

    describe 'backup create fails' do
      using RSpec::Parameterized::TableSyntax

      file_backup_error = Backup::FileBackupError.new('/tmp', '/tmp/backup/uploads')
      config = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash
      db_file_name = File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz')
      db_backup_error = Backup::DatabaseBackupError.new(config, db_file_name)

      where(:backup_class, :rake_task, :error) do
        Backup::Database | 'gitlab:backup:db:create'        | db_backup_error
        Backup::Files    | 'gitlab:backup:builds:create'    | file_backup_error
        Backup::Files    | 'gitlab:backup:uploads:create'   | file_backup_error
        Backup::Files    | 'gitlab:backup:artifacts:create' | file_backup_error
        Backup::Files    | 'gitlab:backup:pages:create'     | file_backup_error
        Backup::Files    | 'gitlab:backup:lfs:create'       | file_backup_error
        Backup::Files    | 'gitlab:backup:registry:create'  | file_backup_error
      end

      with_them do
        before do
          allow_next_instance_of(backup_class) do |instance|
            allow(instance).to receive(:dump).and_raise(error)
          end
        end

        it "raises an error with message" do
          expect { run_rake_task(rake_task) }.to output(Regexp.new(error.message)).to_stdout_from_any_process
        end
      end
    end

    context 'tar creation' do
      context 'archive file permissions' do
        it 'sets correct permissions on the tar file' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          expect(File.exist?(backup_tar)).to be_truthy
          expect(File::Stat.new(backup_tar).mode.to_s(8)).to eq('100600')
        end

        context 'with custom archive_permissions' do
          before do
            allow(Gitlab.config.backup).to receive(:archive_permissions).and_return(0651)
          end

          it 'uses the custom permissions' do
            expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

            expect(File::Stat.new(backup_tar).mode.to_s(8)).to eq('100651')
          end
        end
      end

      it 'sets correct permissions on the tar contents' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        tar_contents, exit_status = Gitlab::Popen.popen(
          %W{tar -tvf #{backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz terraform_state.tar.gz registry.tar.gz packages.tar.gz}
        )

        puts "CONTENT: #{tar_contents}"

        expect(exit_status).to eq(0)
        expect(tar_contents).to match('db')
        expect(tar_contents).to match('uploads.tar.gz')
        expect(tar_contents).to match('repositories/')
        expect(tar_contents).to match('builds.tar.gz')
        expect(tar_contents).to match('artifacts.tar.gz')
        expect(tar_contents).to match('pages.tar.gz')
        expect(tar_contents).to match('lfs.tar.gz')
        expect(tar_contents).to match('terraform_state.tar.gz')
        expect(tar_contents).to match('registry.tar.gz')
        expect(tar_contents).to match('packages.tar.gz')
        expect(tar_contents).not_to match(%r{^.{4,9}[rwx].* (database.sql.gz|uploads.tar.gz|repositories|builds.tar.gz|pages.tar.gz|artifacts.tar.gz|registry.tar.gz)/$})
      end

      it 'deletes temp directories' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        temp_dirs = Dir.glob(
          File.join(Gitlab.config.backup.path, '{db,repositories,uploads,builds,artifacts,pages,lfs,terraform_state,registry,packages}')
        )

        expect(temp_dirs).to be_empty
      end

      context 'registry disabled' do
        let(:enable_registry) { false }

        it 'does not create registry.tar.gz' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W{tar -tvf #{backup_tar}}
          )

          expect(exit_status).to eq(0)
          expect(tar_contents).not_to match('registry.tar.gz')
        end
      end
    end

    context 'multiple repository storages' do
      include StubConfiguration

      let(:default_storage_name) { 'default' }
      let(:second_storage_name) { 'test_second_storage' }

      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,terraform_state,registry')
        stub_storage_settings( second_storage_name => {
          'gitaly_address' => Gitlab.config.repositories.storages.default.gitaly_address,
          'path' => TestEnv::SECOND_STORAGE_PATH
        })
      end

      shared_examples 'includes repositories in all repository storages' do
        specify :aggregate_failures do
          project_a = create(:project, :repository)
          project_snippet_a = create(:project_snippet, :repository, project: project_a, author: project_a.first_owner)
          project_b = create(:project, :repository, repository_storage: second_storage_name)
          project_snippet_b = create(
            :project_snippet,
            :repository,
            project: project_b,
            author: project_b.first_owner,
            repository_storage: second_storage_name
          )
          create(:wiki_page, container: project_a)
          create(:design, :with_file, issue: create(:issue, project: project_a))

          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W{tar -tvf #{backup_tar} repositories}
          )

          tar_lines = tar_contents.lines.grep(/\.bundle/)

          expect(exit_status).to eq(0)

          [
            "#{project_a.disk_path}/.+/001.bundle",
            "#{project_a.disk_path}.wiki/.+/001.bundle",
            "#{project_a.disk_path}.design/.+/001.bundle",
            "#{project_b.disk_path}/.+/001.bundle",
            "#{project_snippet_a.disk_path}/.+/001.bundle",
            "#{project_snippet_b.disk_path}/.+/001.bundle"
          ].each do |repo_name|
            expect(tar_lines).to include(a_string_matching(repo_name))
          end
        end
      end

      context 'no concurrency' do
        it_behaves_like 'includes repositories in all repository storages'
      end

      context 'with concurrency' do
        before do
          stub_env('GITLAB_BACKUP_MAX_CONCURRENCY', 4)
        end

        it_behaves_like 'includes repositories in all repository storages'
      end

      context 'REPOSITORIES_STORAGES set' do
        before do
          stub_env('REPOSITORIES_STORAGES', default_storage_name)
        end

        it 'includes repositories in default repository storage', :aggregate_failures do
          project_a = create(:project, :repository)
          project_snippet_a = create(:project_snippet, :repository, project: project_a, author: project_a.first_owner)
          project_b = create(:project, :repository, repository_storage: second_storage_name)
          project_snippet_b = create(
            :project_snippet,
            :repository,
            project: project_b,
            author: project_b.first_owner,
            repository_storage: second_storage_name
          )
          create(:wiki_page, container: project_a)
          create(:design, :with_file, issue: create(:issue, project: project_a))

          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W{tar -tvf #{backup_tar} repositories}
          )

          tar_lines = tar_contents.lines.grep(/\.bundle/)

          expect(exit_status).to eq(0)

          [
            "#{project_a.disk_path}/.+/001.bundle",
            "#{project_a.disk_path}.wiki/.+/001.bundle",
            "#{project_a.disk_path}.design/.+/001.bundle",
            "#{project_snippet_a.disk_path}/.+/001.bundle"
          ].each do |repo_name|
            expect(tar_lines).to include(a_string_matching(repo_name))
          end

          [
            "#{project_b.disk_path}/.+/001.bundle",
            "#{project_snippet_b.disk_path}/.+/001.bundle"
          ].each do |repo_name|
            expect(tar_lines).not_to include(a_string_matching(repo_name))
          end
        end
      end
    end

    context 'concurrency settings' do
      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,terraform_state,registry')

        create(:project, :repository)
      end

      it 'passes through concurrency environment variables' do
        stub_env('GITLAB_BACKUP_MAX_CONCURRENCY', 5)
        stub_env('GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY', 2)

        expect(::Backup::Repositories).to receive(:new)
          .with(anything, strategy: anything, storages: [], paths: [])
          .and_call_original
        expect(::Backup::GitalyBackup).to receive(:new).with(anything, max_parallelism: 5, storage_parallelism: 2, incremental: false).and_call_original

        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process
      end
    end

    context 'CRON env is set' do
      before do
        stub_env('CRON', '1')
      end

      it 'does not output to stdout' do
        expect { run_rake_task('gitlab:backup:create') }.not_to output.to_stdout_from_any_process
      end
    end
  end
  # backup_create task

  describe "Skipping items in a backup" do
    before do
      stub_env('SKIP', 'an-unknown-type,repositories,uploads,anotherunknowntype')

      create(:project, :repository)
    end

    it "does not contain repositories and uploads" do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      tar_contents, _exit_status = Gitlab::Popen.popen(
        %W{tar -tvf #{backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz terraform_state.tar.gz registry.tar.gz packages.tar.gz}
      )

      expect(tar_contents).to match('db/')
      expect(tar_contents).to match('uploads.tar.gz: Not found in archive')
      expect(tar_contents).to match('builds.tar.gz')
      expect(tar_contents).to match('artifacts.tar.gz')
      expect(tar_contents).to match('lfs.tar.gz')
      expect(tar_contents).to match('terraform_state.tar.gz')
      expect(tar_contents).to match('pages.tar.gz')
      expect(tar_contents).to match('registry.tar.gz')
      expect(tar_contents).to match('packages.tar.gz')
      expect(tar_contents).not_to match('repositories/')
      expect(tar_contents).to match('repositories: Not found in archive')
    end

    it 'does not invoke restore of repositories and uploads' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect_next_instance_of(::Backup::Manager) do |instance|
        (backup_types - %w{repositories uploads}).each do |subtask|
          expect(instance).to receive(:run_restore_task).with(subtask).ordered
        end
        expect(instance).not_to receive(:run_restore_task)
      end
      expect(Rake::Task['gitlab:shell:setup']).to receive :invoke
      expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process
    end
  end

  describe 'skipping tar archive creation' do
    before do
      stub_env('SKIP', 'tar')

      create(:project, :repository)
    end

    it 'created files with backup content and no tar archive' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      dir_contents = Dir.children(Gitlab.config.backup.path)

      expect(dir_contents).to contain_exactly(
        'backup_information.yml',
        'db',
        'uploads.tar.gz',
        'builds.tar.gz',
        'artifacts.tar.gz',
        'lfs.tar.gz',
        'terraform_state.tar.gz',
        'pages.tar.gz',
        'registry.tar.gz',
        'packages.tar.gz',
        'repositories'
      )
    end

    it 'those component files can be restored from' do
      expect { run_rake_task("gitlab:backup:create") }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect_next_instance_of(::Backup::Manager) do |instance|
        backup_types.each do |subtask|
          expect(instance).to receive(:run_restore_task).with(subtask).ordered
        end
        expect(instance).not_to receive(:run_restore_task)
      end
      expect(Rake::Task['gitlab:shell:setup']).to receive :invoke
      expect { run_rake_task("gitlab:backup:restore") }.to output.to_stdout_from_any_process
    end
  end

  describe "Human Readable Backup Name" do
    it 'name has human readable time' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      expect(backup_tar).to match(/\d+_\d{4}_\d{2}_\d{2}_\d+\.\d+\.\d+.*_gitlab_backup.tar$/)
    end
  end
end
# gitlab:app namespace
