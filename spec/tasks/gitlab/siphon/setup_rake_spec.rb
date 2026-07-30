# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:siphon:setup', :silence_stdout, feature_category: :database do
  include RakeHelpers

  let(:task_name) { 'gitlab:siphon:setup' }
  let(:all_roles) { %w[siphon siphon_replicator siphon_snapshot] }
  let(:existing_roles) { all_roles }
  let(:current_user) { 'gitlab' }
  let(:publication_owner) { current_user }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/siphon/setup'
    Rake::Task.define_task(:gitlab_environment)
  end

  before do
    Rake::Task[task_name].reenable

    allow(Gitlab::Database::EachDatabase).to receive(:each_connection).and_yield(connection, 'main')

    allow(connection).to receive(:execute)
    allow(connection).to receive_messages(schema_exists?: true, select_values: existing_roles)
    allow(connection).to receive(:quote) { |value| "'#{value}'" }
    allow(connection).to receive(:quote_column_name) { |value| %("#{value}") }
    allow(connection).to receive(:quote_table_name) { |value| %("#{value}") }
    allow(connection).to receive(:select_value) do |sql|
      sql.include?('pubowner') ? publication_owner : current_user
    end
  end

  def statement_invalid(cause)
    ActiveRecord::StatementInvalid.new.tap do |error|
      allow(error).to receive(:cause).and_return(cause)
    end
  end

  describe 'the helper function' do
    it 'creates it, schema-qualified and hardened' do
      run_rake_task(task_name)

      expect(connection).to have_received(:execute).with(
        a_string_including('CREATE OR REPLACE FUNCTION public.siphon_alter_publication')
          .and(including("SET search_path = ''"))
          .and(including('SECURITY DEFINER'))
      )
    end

    it 'revokes EXECUTE from PUBLIC and grants it only to the control role', :aggregate_failures do
      run_rake_task(task_name)

      expect(connection).to have_received(:execute)
        .with('REVOKE EXECUTE ON FUNCTION public.siphon_alter_publication(text, text, integer) FROM PUBLIC')
      expect(connection).to have_received(:execute)
        .with('GRANT EXECUTE ON FUNCTION public.siphon_alter_publication(text, text, integer) TO "siphon"')
      expect(connection).not_to have_received(:execute).with(/GRANT EXECUTE .* TO "siphon_replicator"/)
    end

    context 'when it already exists and is owned by another role' do
      before do
        allow(connection).to receive(:execute)
          .with(a_string_including('CREATE OR REPLACE FUNCTION'))
          .and_raise(statement_invalid(PG::InsufficientPrivilege.new))
      end

      it 'warns with the fix and does not raise' do
        expect { run_rake_task(task_name) }
          .to output(/owned by another role.*ALTER FUNCTION .* OWNER TO gitlab/m).to_stderr
      end

      it 'does not try to change the grants it cannot change' do
        run_rake_task(task_name)

        expect(connection).not_to have_received(:execute).with(/REVOKE EXECUTE/)
      end
    end
  end

  describe 'the publication' do
    it 'creates one named after the database' do
      run_rake_task(task_name)

      expect(connection).to have_received(:execute).with('CREATE PUBLICATION "siphon_publication_main_1"')
    end

    it 'never transfers ownership away from the current user' do
      run_rake_task(task_name)

      expect(connection).not_to have_received(:execute).with(/OWNER TO/)
    end

    it 'is not created FOR ALL TABLES, which would need a superuser' do
      run_rake_task(task_name)

      expect(connection).not_to have_received(:execute).with(/FOR ALL TABLES/)
    end

    context 'when it already exists' do
      before do
        allow(connection).to receive(:execute)
          .with(a_string_including('CREATE PUBLICATION'))
          .and_raise(statement_invalid(PG::DuplicateObject.new))
      end

      it 'reports it and does not raise' do
        expect { run_rake_task(task_name) }.to output(/already exists/).to_stdout
      end

      it 'still applies the grants' do
        run_rake_task(task_name)

        expect(connection).to have_received(:execute).with(/GRANT SELECT ON ALL TABLES IN SCHEMA public/)
      end

      context 'and is owned by another role' do
        let(:publication_owner) { 'siphon' }

        it 'warns that the function will not be able to alter it' do
          expect { run_rake_task(task_name) }
            .to output(/owned by siphon.*ALTER PUBLICATION .* OWNER TO gitlab/m).to_stderr
        end
      end
    end

    context 'when an unexpected database error occurs' do
      before do
        allow(connection).to receive(:execute)
          .with(a_string_including('CREATE PUBLICATION'))
          .and_raise(statement_invalid(StandardError.new))
      end

      it 're-raises' do
        expect { run_rake_task(task_name) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  describe 'the grants' do
    %w[public gitlab_partitions_dynamic gitlab_partitions_static].each do |schema|
      it "grants USAGE, SELECT and default privileges on #{schema}", :aggregate_failures do
        run_rake_task(task_name)

        roles = '"siphon", "siphon_replicator", "siphon_snapshot"'

        expect(connection).to have_received(:execute).with("GRANT USAGE ON SCHEMA #{schema} TO #{roles}")
        expect(connection).to have_received(:execute)
          .with("GRANT SELECT ON ALL TABLES IN SCHEMA #{schema} TO #{roles}")
        expect(connection).to have_received(:execute)
          .with("ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema} GRANT SELECT ON TABLES TO #{roles}")
      end
    end

    it 'omits FOR ROLE so ALTER DEFAULT PRIVILEGES applies to the connected role' do
      run_rake_task(task_name)

      expect(connection).not_to have_received(:execute).with(/ALTER DEFAULT PRIVILEGES FOR ROLE/)
    end

    it 'skips schemas that do not exist' do
      allow(connection).to receive(:schema_exists?).with('public').and_return(true)
      allow(connection).to receive(:schema_exists?).with('gitlab_partitions_dynamic').and_return(false)
      allow(connection).to receive(:schema_exists?).with('gitlab_partitions_static').and_return(false)

      run_rake_task(task_name)

      expect(connection).not_to have_received(:execute).with(/gitlab_partitions_/)
    end
  end

  describe 'missing roles' do
    context 'when one role is absent' do
      let(:existing_roles) { %w[siphon siphon_snapshot] }

      it 'warns about it' do
        expect { run_rake_task(task_name) }
          .to output(/role siphon_replicator does not exist, skipping it/).to_stderr
      end

      it 'grants only to the roles that exist' do
        run_rake_task(task_name)

        expect(connection).to have_received(:execute)
          .with('GRANT SELECT ON ALL TABLES IN SCHEMA public TO "siphon", "siphon_snapshot"')
      end
    end

    context 'when no roles are present' do
      let(:existing_roles) { [] }

      it 'prints the CREATE USER statements a superuser needs to run' do
        expect { run_rake_task(task_name) }
          .to output(/CREATE USER siphon_replicator WITH REPLICATION/).to_stderr
      end

      it 'does not touch the database and does not raise', :aggregate_failures do
        expect { run_rake_task(task_name) }.not_to raise_error

        expect(connection).not_to have_received(:execute)
      end
    end
  end

  describe 'configuration' do
    it 'iterates every configured database, skipping shared connections' do
      run_rake_task(task_name)

      expect(Gitlab::Database::EachDatabase)
        .to have_received(:each_connection).with(only: nil, include_shared: false)
    end

    context 'with SIPHON_DATABASE set' do
      it 'limits the run to that database' do
        stub_env('SIPHON_DATABASE', 'ci')

        run_rake_task(task_name)

        expect(Gitlab::Database::EachDatabase)
          .to have_received(:each_connection).with(only: 'ci', include_shared: false)
      end
    end

    context 'with SIPHON_USER_PREFIX set' do
      let(:existing_roles) { %w[acme acme_replicator acme_snapshot] }

      it 'derives the role names from it' do
        stub_env('SIPHON_USER_PREFIX', 'acme')

        run_rake_task(task_name)

        expect(connection).to have_received(:execute)
          .with('GRANT EXECUTE ON FUNCTION public.siphon_alter_publication(text, text, integer) TO "acme"')
      end

      it 'aborts when it is not a valid identifier' do
        stub_env('SIPHON_USER_PREFIX', 'bad-prefix; DROP TABLE users')

        expect { run_rake_task(task_name) }
          .to raise_error(SystemExit)
          .and output(/Invalid identifier/).to_stderr
      end
    end

    context 'with SIPHON_PUBLICATION_NAME set' do
      it 'uses it when a single database is targeted' do
        stub_env('SIPHON_PUBLICATION_NAME', 'custom_pub')
        stub_env('SIPHON_DATABASE', 'main')

        run_rake_task(task_name)

        expect(connection).to have_received(:execute).with('CREATE PUBLICATION "custom_pub"')
      end

      it 'aborts without SIPHON_DATABASE, since one name cannot serve several databases' do
        stub_env('SIPHON_PUBLICATION_NAME', 'custom_pub')

        expect { run_rake_task(task_name) }
          .to raise_error(SystemExit)
          .and output(/requires SIPHON_DATABASE/).to_stderr
      end
    end
  end

  describe 'consecutive invocations' do
    it 'succeeds when everything already exists' do
      allow(connection).to receive(:execute)
        .with(a_string_including('CREATE PUBLICATION'))
        .and_raise(statement_invalid(PG::DuplicateObject.new))

      expect { run_rake_task(task_name) }.not_to raise_error

      Rake::Task[task_name].reenable

      expect { run_rake_task(task_name) }.not_to raise_error
    end
  end
end
