# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:setup namespace rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/setup'
  end

  describe 'setup' do
    subject(:setup_task) { run_rake_task('gitlab:setup') }

    let(:storages) do
      {
        'name1' => 'some details',
        'name2' => 'other details'
      }
    end

    let(:server_service1) { double(:server_service) }
    let(:server_service2) { double(:server_service) }

    let(:connections) { Gitlab::Database.database_base_models.values.map(&:connection) }

    before do
      allow(Gitlab).to receive_message_chain('config.repositories.storages').and_return(storages)

      stub_warn_user_is_not_gitlab

      allow(main_object).to receive(:ask_to_continue)
    end

    it 'sets up the application', :aggregate_failures do
      expect_gitaly_connections_to_be_checked

      expect_connections_to_be_terminated
      expect_database_to_be_setup

      setup_task
    end

    context 'when an environment variable is set to force execution' do
      before do
        stub_env('force', 'yes')
      end

      it 'sets up the application without prompting the user', :aggregate_failures do
        expect_gitaly_connections_to_be_checked

        expect(main_object).not_to receive(:ask_to_continue)

        expect_connections_to_be_terminated
        expect_database_to_be_setup

        setup_task
      end
    end

    context 'when the gitaly connection check raises an error' do
      it 'exits the task without setting up the database', :aggregate_failures do
        expect(Gitlab::GitalyClient::ServerService).to receive(:new).with('name1').and_return(server_service1)
        expect(server_service1).to receive(:info).and_raise(GRPC::Unavailable)

        expect_connections_not_to_be_terminated
        expect_database_not_to_be_setup

        expect { setup_task }.to output(/Failed to connect to Gitaly/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'when the task is aborted' do
      it 'exits without setting up the database', :aggregate_failures do
        expect_gitaly_connections_to_be_checked

        expect(main_object).to receive(:ask_to_continue).and_raise(Gitlab::TaskAbortedByUserError)

        expect_connections_not_to_be_terminated
        expect_database_not_to_be_setup

        expect { setup_task }.to output(/Quitting/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'when in the production environment' do
      it 'sets up the database without terminating connections', :aggregate_failures do
        expect_gitaly_connections_to_be_checked

        expect(Rails.env).to receive(:production?).and_return(true)

        expect_connections_not_to_be_terminated
        expect_database_to_be_setup

        setup_task
      end
    end

    context 'when the database is not found when terminating connections' do
      it 'continues setting up the database', :aggregate_failures do
        expect_gitaly_connections_to_be_checked

        expect(connections).to all(receive(:execute).and_raise(ActiveRecord::NoDatabaseError))

        expect_database_to_be_setup

        setup_task
      end
    end

    def expect_gitaly_connections_to_be_checked
      expect(Gitlab::GitalyClient::ServerService).to receive(:new).with('name1').and_return(server_service1)
      expect(server_service1).to receive(:info)

      expect(Gitlab::GitalyClient::ServerService).to receive(:new).with('name2').and_return(server_service2)
      expect(server_service2).to receive(:info)
    end

    def expect_connections_to_be_terminated
      expect(connections).to all(receive(:execute).with(/SELECT pg_terminate_backend/))
    end

    def expect_connections_not_to_be_terminated
      connections.each do |connection|
        expect(connection).not_to receive(:execute)
      end
    end

    def expect_database_to_be_setup
      expect(Rake::Task['db:reset']).to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).to receive(:invoke)
    end

    def expect_database_not_to_be_setup
      expect(Rake::Task['db:reset']).not_to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
    end
  end
end
