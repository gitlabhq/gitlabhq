require 'spec_helper'
require 'rake'

describe 'gitlab:app namespace rake task' do
  before :all do
    Rake.application.rake_require "tasks/gitlab/task_helpers"
    Rake.application.rake_require "tasks/gitlab/backup"
    Rake.application.rake_require "tasks/gitlab/shell"
    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end

  describe 'backup_restore' do
    before do
      # avoid writing task output to spec progress
      allow($stdout).to receive :write
    end

    context 'gitlab version' do
      before do
        Dir.stub glob: []
        allow(Dir).to receive :chdir
        File.stub exists?: true
        Kernel.stub system: true
        FileUtils.stub cp_r: true
        FileUtils.stub mv: true
        Rake::Task["gitlab:shell:setup"].stub invoke: true
      end

      let(:gitlab_version) { Gitlab::VERSION }

      it 'should fail on mismatch' do
        YAML.stub load_file: {gitlab_version: "not #{gitlab_version}" }
        expect { run_rake_task('gitlab:backup:restore') }.to(
          raise_error SystemExit
        )
      end

      it 'should invoke restoration on mach' do
        YAML.stub load_file: {gitlab_version: gitlab_version}
        expect(Rake::Task["gitlab:backup:db:restore"]).to receive :invoke
        expect(Rake::Task["gitlab:backup:repo:restore"]).to receive :invoke
        expect(Rake::Task["gitlab:shell:setup"]).to receive :invoke
        expect { run_rake_task('gitlab:backup:restore') }.to_not raise_error
      end
    end

  end # backup_restore task

  describe 'backup_create' do
    def tars_glob
      Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
    end

    before :all do
      # Record the existing backup tars so we don't touch them
      existing_tars = tars_glob

      # Redirect STDOUT and run the rake task
      orig_stdout = $stdout
      $stdout = StringIO.new
      run_rake_task('gitlab:backup:create')
      $stdout = orig_stdout

      @backup_tar = (tars_glob - existing_tars).first
    end

    after :all do
      FileUtils.rm(@backup_tar)
    end

    it 'should set correct permissions on the tar file' do
      expect(File.exist?(@backup_tar)).to be_truthy
      expect(File::Stat.new(@backup_tar).mode.to_s(8)).to eq('100600')
    end

    it 'should set correct permissions on the tar contents' do
      tar_contents, exit_status = Gitlab::Popen.popen(
        %W{tar -tvf #{@backup_tar} db uploads repositories}
      )
      expect(exit_status).to eq(0)
      expect(tar_contents).to match('db/')
      expect(tar_contents).to match('uploads/')
      expect(tar_contents).to match('repositories/')
      expect(tar_contents).not_to match(/^.{4,9}[rwx].* (db|uploads|repositories)\/$/)
    end

    it 'should delete temp directories' do
      temp_dirs = Dir.glob(
        File.join(Gitlab.config.backup.path, '{db,repositories,uploads}')
      )

      expect(temp_dirs).to be_empty
    end
  end # backup_create task

  describe "Skipping items" do
    def tars_glob
      Dir.glob(File.join(Gitlab.config.backup.path, '*_gitlab_backup.tar'))
    end

    before :all do
      @origin_cd = Dir.pwd

      Rake::Task["gitlab:backup:db:create"].reenable
      Rake::Task["gitlab:backup:repo:create"].reenable
      Rake::Task["gitlab:backup:uploads:create"].reenable

      # Record the existing backup tars so we don't touch them
      existing_tars = tars_glob

      # Redirect STDOUT and run the rake task
      orig_stdout = $stdout
      $stdout = StringIO.new
      ENV["SKIP"] = "repositories"
      run_rake_task('gitlab:backup:create')
      $stdout = orig_stdout

      @backup_tar = (tars_glob - existing_tars).first
    end

    after :all do
      FileUtils.rm(@backup_tar)
      Dir.chdir @origin_cd
    end

    it "does not contain skipped item" do
      tar_contents, exit_status = Gitlab::Popen.popen(
        %W{tar -tvf #{@backup_tar} db uploads repositories}
      )

      expect(tar_contents).to match('db/')
      expect(tar_contents).to match('uploads/')
      expect(tar_contents).not_to match('repositories/')
    end

    it 'does not invoke repositories restore' do
      Rake::Task["gitlab:shell:setup"].stub invoke: true
      allow($stdout).to receive :write

      expect(Rake::Task["gitlab:backup:db:restore"]).to receive :invoke
      expect(Rake::Task["gitlab:backup:repo:restore"]).not_to receive :invoke
      expect(Rake::Task["gitlab:shell:setup"]).to receive :invoke
      expect { run_rake_task('gitlab:backup:restore') }.to_not raise_error
    end
  end
end # gitlab:app namespace
