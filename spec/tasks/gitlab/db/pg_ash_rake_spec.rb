# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:pg_ash namespace rake tasks', feature_category: :database do
  let(:installer) { instance_double(Gitlab::Database::PgAsh::Installer) }

  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/db/pg_ash'
  end

  before do
    allow(Gitlab::Database::PgAsh::Installer).to receive(:new).and_return(installer)
  end

  describe 'install' do
    before do
      allow(installer).to receive(:install).and_return('2.0-beta1')
    end

    it 'reports a fresh install' do
      allow(installer).to receive(:installed_version).and_return(nil)

      expect { run_rake_task('gitlab:db:pg_ash:install') }
        .to output("pg_ash 2.0-beta1 installed.\n").to_stdout
    end

    it 'aborts when a different version is installed' do
      allow(installer).to receive(:installed_version).and_return('1.5')
      allow(installer).to receive(:install)
        .and_raise(Gitlab::Database::PgAsh::Installer::VersionMismatchError, 'pg_ash 1.5 is installed')

      expect { run_rake_task('gitlab:db:pg_ash:install') }
        .to raise_error(SystemExit)
        .and output(/pg_ash 1.5 is installed/).to_stderr
    end

    it 'reports a re-apply when the same version is installed' do
      allow(installer).to receive(:installed_version).and_return('2.0-beta1')

      expect { run_rake_task('gitlab:db:pg_ash:install') }
        .to output("pg_ash 2.0-beta1 re-applied.\n").to_stdout
    end

    it 'aborts with the guidance message when the user cannot create the schema' do
      allow(installer).to receive(:installed_version).and_return(nil)
      allow(installer).to receive(:install)
        .and_raise(Gitlab::Database::PgAsh::Installer::PermissionError, 'GRANT CREATE ON DATABASE')

      expect { run_rake_task('gitlab:db:pg_ash:install') }
        .to raise_error(SystemExit)
        .and output(/GRANT CREATE ON DATABASE/).to_stderr
    end
  end

  describe 'uninstall' do
    it 'reports removal' do
      allow(installer).to receive(:uninstall).and_return(true)

      expect { run_rake_task('gitlab:db:pg_ash:uninstall') }.to output("pg_ash removed.\n").to_stdout
    end

    it 'reports when pg_ash was not installed' do
      allow(installer).to receive(:uninstall).and_return(false)

      expect { run_rake_task('gitlab:db:pg_ash:uninstall') }.to output("pg_ash is not installed.\n").to_stdout
    end
  end

  describe 'status' do
    it 'prints every metric' do
      allow(installer).to receive(:status).and_return('version' => '2.0-beta1', 'sampling_enabled' => 'false')

      expect { run_rake_task('gitlab:db:pg_ash:status') }
        .to output("version                      2.0-beta1\nsampling_enabled             false\n").to_stdout
    end

    it 'reports when pg_ash is not installed' do
      allow(installer).to receive(:status).and_return(nil)

      expect { run_rake_task('gitlab:db:pg_ash:status') }.to output("pg_ash is not installed.\n").to_stdout
    end
  end
end
