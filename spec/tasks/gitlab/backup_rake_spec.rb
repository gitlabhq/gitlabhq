# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:backup namespace rake tasks', :reestablished_active_record_base, :delete, feature_category: :backup_restore do
  let(:enable_registry) { true }
  let(:backup_restore_pid_path) { "#{Rails.application.root}/tmp/backup_restore.pid" }
  let(:backup_rake_task_names) do
    %w[db repo uploads builds artifacts pages lfs terraform_state registry packages ci_secure_files external_diffs]
  end

  let(:progress) { StringIO.new }

  let(:backup_task_ids) do
    %w[
      db repositories uploads builds artifacts pages lfs terraform_state registry packages ci_secure_files
      external_diffs
    ]
  end

  def tars_glob
    Dir.glob(backup_path.join('*_gitlab_backup.tar'))
  end

  def backup_tar
    tars_glob.first
  end

  def backup_path
    Pathname(Gitlab.config.backup.path)
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
    FileUtils.mkdir_p('tmp/tests/public/uploads')
    reenable_backup_sub_tasks
    stub_container_registry_config(enabled: enable_registry)
  end

  after do
    FileUtils.rm(tars_glob, force: true)
    FileUtils.rm(backup_restore_pid_path, force: true)
    FileUtils.rm_rf('tmp/tests/public/uploads', secure: true)
  end

  def reenable_backup_sub_tasks
    backup_rake_task_names.each do |subtask|
      Rake::Task["gitlab:backup:#{subtask}:create"].reenable
    end
  end

  describe 'lock parallel backups' do
    let(:progress) { $stdout }
    let(:delete_message) { /-- Deleting backup and restore PID file at/ }
    let(:pid_file) do
      File.open(backup_restore_pid_path, File::RDWR | File::CREAT)
    end

    before do
      allow(Kernel).to receive(:system).and_return(true)
      allow(YAML).to receive(:safe_load_file).and_return({ gitlab_version: Gitlab::VERSION })
    end

    context 'when a process is running in parallel' do
      before do
        File.open(backup_restore_pid_path, 'wb') do |file|
          file.write('123456')
          file.close
        end
      end

      it 'exits the new process' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(backup_restore_pid_path, any_args).and_yield(pid_file)
        allow(Process).to receive(:getpgid).with(123456).and_return(123456)

        expect { run_rake_task('gitlab:backup:create') }.to raise_error(SystemExit).and output(
          <<~MESSAGE
            Backup and restore in progress:
              There is a backup and restore task in progress (PID 123456).
              Try to run the current task once the previous one ends.
          MESSAGE
        ).to_stdout
      end
    end

    context 'when no process is running in parallel but a PID file exists' do
      let(:rewritten_message) do
        <<~MESSAGE
          The PID file #{backup_restore_pid_path} exists and contains 123456, but the process is not running.
          The PID file will be rewritten with the current process ID #{Process.pid}.
        MESSAGE
      end

      before do
        File.open(backup_restore_pid_path, 'wb') do |file|
          file.write('123456')
          file.close
        end
      end

      it 'rewrites, locks and deletes the PID file while logging a message' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(backup_restore_pid_path, any_args).and_yield(pid_file)
        allow(Process).to receive(:getpgid).with(123456).and_raise(Errno::ESRCH)
        allow(progress).to receive(:puts).with(delete_message).once
        allow(progress).to receive(:puts).with(rewritten_message).once

        allow_next_instance_of(::Backup::Manager) do |manager|
          task = manager.find_task('db')
          allow(manager).to receive(:run_restore_task).with(task)
        end

        expect(pid_file).to receive(:flock).with(File::LOCK_EX)
        expect(pid_file).to receive(:flock).with(File::LOCK_UN)
        expect(File).to receive(:delete).with(backup_restore_pid_path)
        expect(progress).to receive(:puts).with(rewritten_message).once
        expect(progress).to receive(:puts).with(delete_message).once

        run_rake_task('gitlab:backup:db:restore')
      end
    end

    context 'when no process is running in parallel' do
      using RSpec::Parameterized::TableSyntax

      where(:task_name, :rake_task) do
        'db'              | 'gitlab:backup:db:restore'
        'repositories'    | 'gitlab:backup:repo:restore'
        'builds'          | 'gitlab:backup:builds:restore'
        'uploads'         | 'gitlab:backup:uploads:restore'
        'artifacts'       | 'gitlab:backup:artifacts:restore'
        'pages'           | 'gitlab:backup:pages:restore'
        'lfs'             | 'gitlab:backup:lfs:restore'
        'terraform_state' | 'gitlab:backup:terraform_state:restore'
        'registry'        | 'gitlab:backup:registry:restore'
        'packages'        | 'gitlab:backup:packages:restore'
      end

      with_them do
        before do
          allow(File).to receive(:open).and_call_original
          allow(File).to receive(:open).with(backup_restore_pid_path, any_args).and_yield(pid_file)
          allow(File).to receive(:delete).with(backup_restore_pid_path)
          allow(progress).to receive(:puts).at_least(:once)

          allow_next_instance_of(::Backup::Manager) do |manager|
            Array(task_name).each do |t|
              task = manager.find_task(t)
              allow(manager).to receive(:run_restore_task).with(task)
            end
          end
        end

        it 'locks and deletes the PID file while logging a message' do
          expect(pid_file).to receive(:flock).with(File::LOCK_EX)
          expect(pid_file).to receive(:flock).with(File::LOCK_UN)
          expect(File).to receive(:delete).with(backup_restore_pid_path)
          expect(progress).to receive(:puts).with(delete_message)

          run_rake_task(rake_task)
        end
      end
    end
  end

  describe 'backup_restore' do
    context 'with gitlab version' do
      before do
        allow(Dir).to receive(:glob).and_return(['1_gitlab_backup.tar'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(backup_restore_pid_path).and_return(false)
        allow(Kernel).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:cp_r).and_return(true)
        allow(FileUtils).to receive(:mv).and_return(true)
        allow(Rake::Task["gitlab:shell:setup"])
          .to receive(:invoke).and_return(true)
      end

      let(:gitlab_version) { Gitlab::VERSION }

      context 'when restore matches gitlab version' do
        before do
          allow(YAML).to receive(:safe_load_file)
            .and_return({ gitlab_version: gitlab_version })
          expect_next_instance_of(::Backup::Manager) do |manager|
            backup_task_ids.each do |t|
              task = manager.find_task(t)

              expect(manager).to receive(:run_restore_task).with(task).ordered
            end
            expect(manager).not_to receive(:run_restore_task)
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
        # We only need a backup of the repositories and the DB for this test
        stub_env('SKIP', 'uploads,builds,artifacts,lfs,terraform_state,registry')
      end

      it 'removes stale data' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        excluded_project = create(:project, :repository, name: 'mepmep')

        expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process

        raw_repo = excluded_project.repository.raw

        expect(Project.find_by_full_path(excluded_project.full_path)).to be_nil
        expect(raw_repo).not_to exist
      end
    end

    context 'when the backup is restored' do
      let!(:included_project) { create(:project_with_design, :repository) }
      let!(:original_checksum) { included_project.repository.checksum }

      before do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        backup_tar = Dir.glob(backup_path.join('*_gitlab_backup.tar')).last
        allow(Dir).to receive(:glob).and_return([backup_tar])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(backup_restore_pid_path).and_return(false)
        allow(Kernel).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:cp_r).and_return(true)
        allow(FileUtils).to receive(:mv).and_return(true)
        allow(YAML).to receive(:safe_load_file)
          .and_return({ gitlab_version: Gitlab::VERSION })

        expect_next_instance_of(::Backup::Manager) do |manager|
          backup_task_ids.each do |t|
            task = manager.find_task(t)
            expect(manager).to receive(:run_restore_task).with(task).ordered
          end
          expect(manager).not_to receive(:run_restore_task)
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
      allow(ApplicationRecord.connection).to receive(:reconnect!)
      allow(Ci::ApplicationRecord.connection).to receive(:reconnect!)
    end

    let!(:project) { create(:project_with_design, :repository) }

    context 'with specific backup tasks' do
      before do
        stub_env('SKIP', 'db')
        allow_next_instance_of(Gitlab::BackupLogger) do |instance|
          allow(instance).to receive(:info).and_call_original
        end
      end

      it 'prints a progress message to stdout' do
        backup_rake_task_names.each do |task|
          expect { run_rake_task("gitlab:backup:#{task}:create") }.to output(/Dumping /).to_stdout_from_any_process
        end
      end

      it 'logs the progress to log file' do
        expect_logger_to_receive_messages([
          "Dumping database ... [SKIPPED]",
          "Dumping repositories ... ",
          "Dumping repositories ... done",
          "Dumping uploads ... ",
          "Dumping uploads ... done",
          "Dumping builds ... ",
          "Dumping builds ... done",
          "Dumping artifacts ... ",
          "Dumping artifacts ... done",
          "Dumping pages ... ",
          "Dumping pages ... done",
          "Dumping lfs objects ... ",
          "Dumping lfs objects ... done",
          "Dumping terraform states ... ",
          "Dumping terraform states ... done",
          "Dumping container registry images ... ",
          "Dumping container registry images ... done",
          "Dumping packages ... ",
          "Dumping packages ... done",
          "Dumping ci secure files ... ",
          "Dumping ci secure files ... done",
          "Dumping external diffs ... ",
          "Dumping external diffs ... done"
        ])

        backup_rake_task_names.each do |task|
          run_rake_task("gitlab:backup:#{task}:create")
        end
      end
    end

    describe 'backup create fails' do
      using RSpec::Parameterized::TableSyntax

      file_backup_error = Backup::FileBackupError.new('/tmp', '/tmp/backup/uploads')
      config = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash
      db_file_name = File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz')
      db_backup_error = Backup::DatabaseBackupError.new(config, db_file_name)

      where(:backup_target_class, :rake_task, :error) do
        Backup::Targets::Database | 'gitlab:backup:db:create'        | db_backup_error
        Backup::Targets::Files    | 'gitlab:backup:builds:create'    | file_backup_error
        Backup::Targets::Files    | 'gitlab:backup:uploads:create'   | file_backup_error
        Backup::Targets::Files    | 'gitlab:backup:artifacts:create' | file_backup_error
        Backup::Targets::Files    | 'gitlab:backup:pages:create'     | file_backup_error
        Backup::Targets::Files    | 'gitlab:backup:lfs:create'       | file_backup_error
        Backup::Targets::Files    | 'gitlab:backup:registry:create'  | file_backup_error
      end

      with_them do
        before do
          allow_next_instance_of(backup_target_class) do |instance|
            allow(instance).to receive(:dump).and_raise(error)
          end
        end

        it "raises an error with message" do
          expect do
            expect { run_rake_task(rake_task) }.to raise_error(SystemExit)
          end.to output(Regexp.new(error.message)).to_stdout_from_any_process
        end

        it "raises an error with message when subtask fails" do
          expect do
            run_rake_task('gitlab:backup:create')
          end.to raise_error(Backup::Error)
        end
      end
    end

    context 'with tar creation' do
      context 'with archive file permissions' do
        it 'sets correct permissions on the tar file' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          expect(File).to exist(backup_tar)
          expect(File::Stat.new(backup_tar).mode.to_s(8)).to eq('100600')
        end

        context 'with custom archive_permissions' do
          before do
            allow(Gitlab.config.backup).to receive(:archive_permissions).and_return(0o651)
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
          %W[
            tar -tvf #{backup_tar}
            db
            uploads.tar.gz
            repositories
            builds.tar.gz
            artifacts.tar.gz
            pages.tar.gz
            lfs.tar.gz
            terraform_state.tar.gz
            registry.tar.gz
            packages.tar.gz
            ci_secure_files.tar.gz
            external_diffs.tar.gz
          ]
        )

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
        expect(tar_contents).to match('ci_secure_files.tar.gz')
        expect(tar_contents).to match('external_diffs.tar.gz')
        expect(tar_contents).not_to match(%r{^.{4,9}[rwx].* (database.sql.gz|uploads.tar.gz|repositories|builds.tar.gz|
                                                             pages.tar.gz|artifacts.tar.gz|registry.tar.gz)/$})
      end

      it 'deletes temp directories' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        temp_dirs = Dir.glob(
          backup_path.join('{db,repositories,uploads,builds,artifacts,pages,lfs,terraform_state,registry,packages}')
        )

        expect(temp_dirs).to be_empty
      end

      context 'when registry is disabled' do
        let(:enable_registry) { false }

        it 'does not create registry.tar.gz' do
          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W[tar -tvf #{backup_tar}]
          )

          expect(exit_status).to eq(0)
          expect(tar_contents).not_to match('registry.tar.gz')
        end
      end
    end

    context 'with multiple repository storages' do
      include StubConfiguration

      let(:default_storage_name) { 'default' }
      let(:second_storage_name) { 'test_second_storage' }

      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,terraform_state,registry')
        stub_storage_settings(second_storage_name => {})
      end

      shared_examples 'includes repositories in all repository storages' do
        specify :aggregate_failures do
          project_a = create(:project_with_design, :repository)
          project_snippet_a = create(:project_snippet, :repository, project: project_a, author: project_a.first_owner)
          project_b = create(:project_with_design, :repository, repository_storage: second_storage_name)
          project_snippet_b = create(
            :project_snippet,
            :repository,
            project: project_b,
            author: project_b.first_owner,
            repository_storage: second_storage_name
          )
          create(:wiki_page, container: project_a)

          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W[tar -tvf #{backup_tar} repositories]
          )

          tar_lines = tar_contents.lines.grep(/\.bundle/)

          expect(exit_status).to eq(0)

          %W[
            #{project_a.repository.relative_path}/.+/001.bundle
            #{project_a.wiki.repository.relative_path}/.+/001.bundle
            #{project_a.design_management_repository.repository.relative_path}/.+/001.bundle
            #{project_b.repository.relative_path}/.+/001.bundle
            #{project_snippet_a.repository.relative_path}/.+/001.bundle
            #{project_snippet_b.repository.relative_path}/.+/001.bundle
          ].each do |repo_name|
            expect(tar_lines).to include(a_string_matching(repo_name))
          end
        end
      end

      context 'with no concurrency' do
        it_behaves_like 'includes repositories in all repository storages'
      end

      context 'with concurrency' do
        before do
          stub_env('GITLAB_BACKUP_MAX_CONCURRENCY', 4)
        end

        it_behaves_like 'includes repositories in all repository storages'
      end

      context 'when REPOSITORIES_STORAGES is set' do
        before do
          stub_env('REPOSITORIES_STORAGES', default_storage_name)
        end

        it 'includes repositories in default repository storage', :aggregate_failures do
          project_a = create(:project_with_design, :repository)
          project_snippet_a = create(:project_snippet, :repository, project: project_a, author: project_a.first_owner)
          project_b = create(:project_with_design, :repository, repository_storage: second_storage_name)
          project_snippet_b = create(
            :project_snippet,
            :repository,
            project: project_b,
            author: project_b.first_owner,
            repository_storage: second_storage_name
          )
          create(:wiki_page, container: project_a)

          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W[tar -tvf #{backup_tar} repositories]
          )

          tar_lines = tar_contents.lines.grep(/\.bundle/)

          expect(exit_status).to eq(0)

          %W[
            #{project_a.repository.relative_path}/.+/001.bundle
            #{project_a.wiki.repository.relative_path}/.+/001.bundle
            #{project_a.design_management_repository.repository.relative_path}/.+/001.bundle
            #{project_snippet_a.repository.relative_path}/.+/001.bundle
          ].each do |repo_name|
            expect(tar_lines).to include(a_string_matching(repo_name))
          end

          %W[
            #{project_b.repository.relative_path}/.+/001.bundle
            #{project_snippet_b.repository.relative_path}/.+/001.bundle
          ].each do |repo_name|
            expect(tar_lines).not_to include(a_string_matching(repo_name))
          end
        end
      end
    end

    context 'with concurrency settings' do
      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,terraform_state,registry')

        create(:project_with_design, :repository)
      end

      it 'passes through concurrency environment variables' do
        stub_env('GITLAB_BACKUP_MAX_CONCURRENCY', 5)
        stub_env('GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY', 2)

        expect(::Backup::Targets::Repositories).to receive(:new)
          .with(anything, strategy: anything, options: anything, storages: [], paths: [], skip_paths: [])
          .and_call_original
        expect(::Backup::GitalyBackup).to receive(:new).with(
          anything,
          max_parallelism: 5,
          storage_parallelism: 2,
          incremental: false,
          server_side: false
        ).and_call_original

        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process
      end
    end

    context 'when CRON env is set' do
      before do
        stub_env('CRON', '1')
      end

      it 'does not output to stdout' do
        expect { run_rake_task('gitlab:backup:create') }.not_to output.to_stdout_from_any_process
      end
    end
  end
  # backup_create task

  describe "skipping items in a backup" do
    before do
      stub_env('SKIP', 'an-unknown-type,repositories,uploads,anotherunknowntype')

      create(:project_with_design, :repository)
    end

    it "does not contain repositories and uploads" do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      tar_contents, _exit_status = Gitlab::Popen.popen(
        %W[
          tar -tvf #{backup_tar}
          db
          uploads.tar.gz
          repositories
          builds.tar.gz
          artifacts.tar.gz
          pages.tar.gz
          lfs.tar.gz
          terraform_state.tar.gz
          registry.tar.gz
          packages.tar.gz
          ci_secure_files.tar.gz
        ]
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
      expect(tar_contents).to match('ci_secure_files.tar.gz')
      expect(tar_contents).not_to match('repositories/')
      expect(tar_contents).to match('repositories: Not found in archive')
    end

    it 'does not invoke restore of repositories and uploads' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect_next_instance_of(::Backup::Manager) do |manager|
        (backup_task_ids - %w[repositories uploads]).each do |t|
          task = manager.find_task(t)
          expect(manager).to receive(:run_restore_task).with(task).ordered
        end
        expect(manager).not_to receive(:run_restore_task)
      end
      expect(Rake::Task['gitlab:shell:setup']).to receive :invoke
      expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process
    end
  end

  describe 'skipping tar archive creation' do
    before do
      stub_env('SKIP', 'tar')

      create(:project_with_design, :repository)
    end

    it 'created files with backup content and no tar archive' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      dir_contents = Dir.children(backup_path)

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
        'repositories',
        'ci_secure_files.tar.gz',
        'external_diffs.tar.gz'
      )
    end

    it 'those component files can be restored from' do
      expect { run_rake_task("gitlab:backup:create") }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect_next_instance_of(::Backup::Manager) do |manager|
        backup_task_ids.each do |t|
          task = manager.find_task(t)

          expect(manager).to receive(:run_restore_task).with(task).ordered
        end
        expect(manager).not_to receive(:run_restore_task)
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

  describe 'verifying a backup' do
    it 'delegates to Backup::Manager#verify!' do
      expect_next_instance_of(::Backup::Manager) do |manager|
        expect(manager).to receive(:verify!)
      end

      run_rake_task('gitlab:backup:verify')
    end
  end

  def expect_logger_to_receive_messages(messages)
    [Gitlab::BackupLogger, Gitlab::Backup::JsonLogger].each do |log_class|
      expect_any_instance_of(log_class) do |logger|
        messages.each do |message|
          allow(logger).to receive(:info).with(message).ordered
        end
      end
    end
  end
end
# gitlab:app namespace
