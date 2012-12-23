require 'spec_helper'
require 'rake'

describe 'gitlab:app namespace rake task' do
  before :all do
    Rake.application.rake_require "tasks/gitlab/backup"
    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  describe 'backup_restore' do
    before do
      # avoid writing task output to spec progress
      $stdout.stub :write
    end

    let :run_rake_task do
      Rake::Task["gitlab:backup:restore"].reenable
      Rake.application.invoke_task "gitlab:backup:restore"
    end

    context 'gitlab version' do
      before do
        Dir.stub :glob => []
        Dir.stub :chdir
        File.stub :exists? => true
        Kernel.stub :system => true
      end

      let(:gitlab_version) { %x{git rev-parse HEAD}.gsub(/\n/,"") }

      it 'should fail on mismach' do
        YAML.stub :load_file => {:gitlab_version => gitlab_version.reverse}
        expect { run_rake_task }.to raise_error SystemExit
      end

      it 'should invoke restoration on mach' do
        YAML.stub :load_file => {:gitlab_version => gitlab_version}
        Rake::Task["gitlab:backup:db:restore"].should_receive :invoke
        Rake::Task["gitlab:backup:repo:restore"].should_receive :invoke
        expect { run_rake_task }.to_not raise_error SystemExit
      end
    end

  end # backup_restore task
end # gitlab:app namespace
