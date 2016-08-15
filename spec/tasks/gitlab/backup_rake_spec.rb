require 'spec_helper'
require 'rake'

describe 'gitlab:app namespace rake task' do
  let(:enable_registry) { true }

  before :all do
    Rake.application.rake_require 'tasks/gitlab/task_helpers'
    Rake.application.rake_require 'tasks/gitlab/backup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/gitlab/db'

    # empty task as env is already loaded
    Rake::Task.define_task :environment

    # We need this directory to run `gitlab:backup:create` task
    FileUtils.mkdir_p('public/uploads')
  end

  before do
    stub_container_registry_config(enabled: enable_registry)
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end

  def reenable_backup_sub_tasks
    %w{db repo uploads builds artifacts pages lfs registry}.each do |subtask|
      Rake::Task["gitlab:backup:#{subtask}:create"].reenable
    end
  end

  describe 'backup_restore' do
    before do
      # avoid writing task output to spec progress
      allow($stdout).to receive :write
    end

    context 'gitlab version' do
      before do
        allow(Dir).to receive(:glob).and_return([])
        allow(Dir).to receive(:chdir)
        allow(File).to receive(:exist?).and_return(true)
        allow(Kernel).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:cp_r).and_return(true)
        allow(FileUtils).to receive(:mv).and_return(true)
        allow(Rake::Task["gitlab:shell:setup"]).
          to receive(:invoke).and_return(true)
        ENV['force'] = 'yes'
      end

      let(:gitlab_version) { Gitlab::VERSION }

      it 'fails on mismatch' do
        allow(YAML).to receive(:load_file).
          and_return({ gitlab_version: "not #{gitlab_version}" })

        expect { run_rake_task('gitlab:backup:restore') }.
          to raise_error(SystemExit)
      end

      it 'invokes restoration on match' do
        allow(YAML).to receive(:load_file).
          and_return({ gitlab_version: gitlab_version })
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
        expect { run_rake_task('gitlab:backup:restore') }.not_to raise_error
      end
    end
  end # backup_restore task

  describe 'backup_create' do
    def tars_glob
      Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
    end

    def create_backup
      FileUtils.rm tars_glob

      # Redirect STDOUT and run the rake task
      orig_stdout = $stdout
      $stdout = StringIO.new
      reenable_backup_sub_tasks
      run_rake_task('gitlab:backup:create')
      reenable_backup_sub_tasks
      $stdout = orig_stdout

      @backup_tar = tars_glob.first
    end

    context 'tar creation' do
      before do
        create_backup
      end

      after do
        FileUtils.rm(@backup_tar)
      end

      context 'archive file permissions' do
        it 'sets correct permissions on the tar file' do
          expect(File.exist?(@backup_tar)).to be_truthy
          expect(File::Stat.new(@backup_tar).mode.to_s(8)).to eq('100600')
        end

        context 'with custom archive_permissions' do
          before do
            allow(Gitlab.config.backup).to receive(:archive_permissions).and_return(0651)
            # We created a backup in a before(:all) so it got the default permissions.
            # We now need to do some work to create a _new_ backup file using our stub.
            FileUtils.rm(@backup_tar)
            create_backup
          end

          it 'uses the custom permissions' do
            expect(File::Stat.new(@backup_tar).mode.to_s(8)).to eq('100651')
          end
        end
      end

      it 'sets correct permissions on the tar contents' do
        tar_contents, exit_status = Gitlab::Popen.popen(
          %W{tar -tvf #{@backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz registry.tar.gz}
        )
        expect(exit_status).to eq(0)
        expect(tar_contents).to match('db/')
        expect(tar_contents).to match('uploads.tar.gz')
        expect(tar_contents).to match('repositories/')
        expect(tar_contents).to match('builds.tar.gz')
        expect(tar_contents).to match('artifacts.tar.gz')
        expect(tar_contents).to match('pages.tar.gz')
        expect(tar_contents).to match('lfs.tar.gz')
        expect(tar_contents).to match('registry.tar.gz')
        expect(tar_contents).not_to match(/^.{4,9}[rwx].* (database.sql.gz|uploads.tar.gz|repositories|builds.tar.gz|pages.tar.gz|artifacts.tar.gz|registry.tar.gz)\/$/)
      end

      it 'deletes temp directories' do
        temp_dirs = Dir.glob(
          File.join(Gitlab.config.backup.path, '{db,repositories,uploads,builds,artifacts,pages,lfs,registry}')
        )

        expect(temp_dirs).to be_empty
      end

      context 'registry disabled' do
        let(:enable_registry) { false }

        it 'does not create registry.tar.gz' do
          tar_contents, exit_status = Gitlab::Popen.popen(
            %W{tar -tvf #{@backup_tar}}
          )
          expect(exit_status).to eq(0)
          expect(tar_contents).not_to match('registry.tar.gz')
        end
      end
    end

    context 'multiple repository storages' do
      let(:project_a) { create(:project, repository_storage: 'default') }
      let(:project_b) { create(:project, repository_storage: 'custom') }

      before do
        FileUtils.mkdir('tmp/tests/default_storage')
        FileUtils.mkdir('tmp/tests/custom_storage')
        storages = {
          'default' => 'tmp/tests/default_storage',
          'custom' => 'tmp/tests/custom_storage'
        }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)

        # Create the projects now, after mocking the settings but before doing the backup
        project_a
        project_b

        # We only need a backup of the repositories for this test
        ENV["SKIP"] = "db,uploads,builds,artifacts,lfs,registry"
        create_backup
      end

      after do
        FileUtils.rm_rf('tmp/tests/default_storage')
        FileUtils.rm_rf('tmp/tests/custom_storage')
        FileUtils.rm(@backup_tar)
      end

      it 'includes repositories in all repository storages' do
        tar_contents, exit_status = Gitlab::Popen.popen(
          %W{tar -tvf #{@backup_tar} repositories}
        )
        expect(exit_status).to eq(0)
        expect(tar_contents).to match("repositories/#{project_a.path_with_namespace}.bundle")
        expect(tar_contents).to match("repositories/#{project_b.path_with_namespace}.bundle")
      end
    end
  end # backup_create task

  describe "Skipping items" do
    def tars_glob
      Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
    end

    before :all do
      @origin_cd = Dir.pwd

      reenable_backup_sub_tasks

      FileUtils.rm tars_glob

      # Redirect STDOUT and run the rake task
      orig_stdout = $stdout
      $stdout = StringIO.new
      ENV["SKIP"] = "repositories,uploads"
      run_rake_task('gitlab:backup:create')
      $stdout = orig_stdout

      @backup_tar = tars_glob.first
    end

    after :all do
      FileUtils.rm(@backup_tar)
      Dir.chdir @origin_cd
    end

    it "does not contain skipped item" do
      tar_contents, _exit_status = Gitlab::Popen.popen(
        %W{tar -tvf #{@backup_tar} db uploads.tar.gz repositories builds.tar.gz artifacts.tar.gz pages.tar.gz lfs.tar.gz registry.tar.gz}
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
      allow(Rake::Task['gitlab:shell:setup']).
        to receive(:invoke).and_return(true)
      allow($stdout).to receive :write

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
      expect { run_rake_task('gitlab:backup:restore') }.not_to raise_error
    end
  end
end # gitlab:app namespace
