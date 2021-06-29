# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:app namespace rake task', :delete do
  let(:enable_registry) { true }

  def tars_glob
    Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
  end

  def backup_tar
    tars_glob.first
  end

  def backup_files
    %w(backup_information.yml artifacts.tar.gz builds.tar.gz lfs.tar.gz pages.tar.gz)
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
    %w{db repo uploads builds artifacts pages lfs registry}.each do |subtask|
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
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:db:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:repo:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:builds:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:uploads:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:artifacts:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:pages:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:lfs:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:backup:registry:restore']).to receive(:invoke)
          expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)
        end

        it 'invokes restoration on match' do
          expect { run_rake_task('gitlab:backup:restore') }.to output.to_stdout_from_any_process
        end

        it 'prints timestamps on messages' do
          expect { run_rake_task('gitlab:backup:restore') }.to output(/.*\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s[-+]\d{4}\s--\s.*/).to_stdout_from_any_process
        end
      end
    end

    context 'when the restore directory is not empty' do
      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,registry')

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

        expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:db:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:repo:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:builds:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:uploads:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:artifacts:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:pages:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:lfs:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:backup:registry:restore']).to receive(:invoke)
        expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)

        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,registry')
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
          expect(tar_contents).to match("#{user_backup_path}/custom_hooks.tar")
          expect(tar_contents).to match("#{user_backup_path}.bundle")
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
        let(:task_list) { %w(db repo uploads builds artifacts pages lfs registry) }

        it 'prints a progress message to stdout' do
          task_list.each do |task|
            expect { run_rake_task("gitlab:backup:#{task}:create") }.to output(/Dumping /).to_stdout_from_any_process
          end
        end

        it 'logs the progress to log file' do
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping database ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "[SKIPPED]")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping repositories ...")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping uploads ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping builds ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping artifacts ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping pages ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping lfs objects ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "Dumping container registry images ... ")
          expect(Gitlab::BackupLogger).to receive(:info).with(message: "done").exactly(7).times

          task_list.each do |task|
            run_rake_task("gitlab:backup:#{task}:create")
          end
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
          %W{tar -tvf #{backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz registry.tar.gz}
        )

        expect(exit_status).to eq(0)
        expect(tar_contents).to match('db')
        expect(tar_contents).to match('uploads.tar.gz')
        expect(tar_contents).to match('repositories/')
        expect(tar_contents).to match('builds.tar.gz')
        expect(tar_contents).to match('artifacts.tar.gz')
        expect(tar_contents).to match('pages.tar.gz')
        expect(tar_contents).to match('lfs.tar.gz')
        expect(tar_contents).to match('registry.tar.gz')
        expect(tar_contents).not_to match(%r{^.{4,9}[rwx].* (database.sql.gz|uploads.tar.gz|repositories|builds.tar.gz|pages.tar.gz|artifacts.tar.gz|registry.tar.gz)/$})
      end

      it 'deletes temp directories' do
        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

        temp_dirs = Dir.glob(
          File.join(Gitlab.config.backup.path, '{db,repositories,uploads,builds,artifacts,pages,lfs,registry}')
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
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,registry')
        stub_storage_settings( second_storage_name => {
          'gitaly_address' => Gitlab.config.repositories.storages.default.gitaly_address,
          'path' => TestEnv::SECOND_STORAGE_PATH
        })
      end

      shared_examples 'includes repositories in all repository storages' do
        specify :aggregate_failures do
          project_a = create(:project, :repository)
          project_snippet_a = create(:project_snippet, :repository, project: project_a, author: project_a.owner)
          project_b = create(:project, :repository, repository_storage: second_storage_name)
          project_snippet_b = create(:project_snippet, :repository, project: project_b, author: project_b.owner)
          project_snippet_b.snippet_repository.update!(shard: project_b.project_repository.shard)
          create(:wiki_page, container: project_a)
          create(:design, :with_file, issue: create(:issue, project: project_a))

          move_repository_to_secondary(project_b)
          move_repository_to_secondary(project_snippet_b)

          expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

          tar_contents, exit_status = Gitlab::Popen.popen(
            %W{tar -tvf #{backup_tar} repositories}
          )

          tar_lines = tar_contents.lines.grep(/\.bundle/)

          expect(exit_status).to eq(0)

          [
            "#{project_a.disk_path}.bundle",
            "#{project_a.disk_path}.wiki.bundle",
            "#{project_a.disk_path}.design.bundle",
            "#{project_b.disk_path}.bundle",
            "#{project_snippet_a.disk_path}.bundle",
            "#{project_snippet_b.disk_path}.bundle"
          ].each do |repo_name|
            expect(tar_lines.grep(/#{repo_name}/).size).to eq 1
          end
        end

        def move_repository_to_secondary(record)
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            default_shard_legacy_path = Gitlab.config.repositories.storages.default.legacy_disk_path
            secondary_legacy_path = Gitlab.config.repositories.storages[second_storage_name].legacy_disk_path
            dst_dir = File.join(secondary_legacy_path, File.dirname(record.disk_path))

            FileUtils.mkdir_p(dst_dir) unless Dir.exist?(dst_dir)

            FileUtils.mv(
              File.join(default_shard_legacy_path, record.disk_path + '.git'),
              File.join(secondary_legacy_path, record.disk_path + '.git')
            )
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
    end

    context 'concurrency settings' do
      before do
        # We only need a backup of the repositories for this test
        stub_env('SKIP', 'db,uploads,builds,artifacts,lfs,registry')

        create(:project, :repository)
      end

      it 'has defaults' do
        expect_next_instance_of(::Backup::Repositories) do |instance|
          expect(instance).to receive(:dump)
            .with(max_concurrency: 1, max_storage_concurrency: 1)
            .and_call_original
        end

        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process
      end

      it 'passes through concurrency environment variables' do
        # The way concurrency is handled will change with the `gitaly_backup`
        # feature flag. For now we need to check that both ways continue to
        # work. This will be cleaned up in the rollout issue.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/333034

        stub_env('GITLAB_BACKUP_MAX_CONCURRENCY', 5)
        stub_env('GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY', 2)

        expect_next_instance_of(::Backup::Repositories) do |instance|
          expect(instance).to receive(:dump)
            .with(max_concurrency: 5, max_storage_concurrency: 2)
            .and_call_original
        end
        expect(::Backup::GitalyBackup).to receive(:new).with(anything, parallel: 5).and_call_original

        expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process
      end
    end
  end
  # backup_create task

  describe "Skipping items" do
    before do
      stub_env('SKIP', 'repositories,uploads')

      create(:project, :repository)
    end

    it "does not contain skipped item" do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      tar_contents, _exit_status = Gitlab::Popen.popen(
        %W{tar -tvf #{backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz registry.tar.gz}
      )

      expect(tar_contents).to match('db/')
      expect(tar_contents).to match('uploads.tar.gz')
      expect(tar_contents).to match('builds.tar.gz')
      expect(tar_contents).to match('artifacts.tar.gz')
      expect(tar_contents).to match('lfs.tar.gz')
      expect(tar_contents).to match('pages.tar.gz')
      expect(tar_contents).to match('registry.tar.gz')
      expect(tar_contents).not_to match('repositories/')
    end

    it 'does not invoke repositories restore' do
      expect { run_rake_task('gitlab:backup:create') }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect(Rake::Task['gitlab:db:drop_tables']).to receive :invoke
      expect(Rake::Task['gitlab:backup:db:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:repo:restore']).not_to receive :invoke
      expect(Rake::Task['gitlab:backup:uploads:restore']).not_to receive :invoke
      expect(Rake::Task['gitlab:backup:builds:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:artifacts:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:pages:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:lfs:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:registry:restore']).to receive :invoke
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
        'pages.tar.gz',
        'registry.tar.gz',
        'repositories',
        'tmp'
      )
    end

    it 'those component files can be restored from' do
      expect { run_rake_task("gitlab:backup:create") }.to output.to_stdout_from_any_process

      allow(Rake::Task['gitlab:shell:setup'])
        .to receive(:invoke).and_return(true)

      expect(Rake::Task['gitlab:db:drop_tables']).to receive :invoke
      expect(Rake::Task['gitlab:backup:db:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:repo:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:uploads:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:builds:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:artifacts:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:pages:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:lfs:restore']).to receive :invoke
      expect(Rake::Task['gitlab:backup:registry:restore']).to receive :invoke
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
