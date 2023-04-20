# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'check_forced_decomposition initializer', feature_category: :cell do
  subject(:check_forced_decomposition) do
    load Rails.root.join('config/initializers/check_forced_decomposition.rb')
  end

  before do
    stub_env('GITLAB_ALLOW_SEPARATE_CI_DATABASE', nil)
  end

  context 'for production env' do
    before do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
    end

    context 'for single database' do
      before do
        skip_if_multiple_databases_are_setup
      end

      it { expect { check_forced_decomposition }.not_to raise_error }
    end

    context 'for multiple database' do
      before do
        skip_if_multiple_databases_not_setup
      end

      let(:main_database_config) do
        Rails.application.config.load_database_yaml
          .dig('test', 'main')
          .slice('adapter', 'encoding', 'database', 'username', 'password', 'host')
          .symbolize_keys
      end

      let(:additional_database_config) do
        # Use built-in postgres database
        main_database_config.merge(database: 'postgres')
      end

      around do |example|
        with_reestablished_active_record_base(reconnect: true) do
          with_db_configs(test: test_config) do
            example.run
          end
        end
      end

      context 'when ci and main share the same database' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: additional_database_config.merge(database: main_database_config[:database])
          }
        end

        it { expect { check_forced_decomposition }.not_to raise_error }

        context 'when host is not present' do
          let(:test_config) do
            {
              main: main_database_config.except(:host),
              ci: additional_database_config.merge(database: main_database_config[:database]).except(:host)
            }
          end

          it { expect { check_forced_decomposition }.not_to raise_error }
        end
      end

      context 'when ci and main share the same database but different host' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: additional_database_config.merge(
              database: main_database_config[:database],
              host: 'otherhost.localhost'
            )
          }
        end

        it { expect { check_forced_decomposition }.to raise_error(/Separate CI database is not ready/) }
      end

      context 'when ci and main are different databases' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: additional_database_config
          }
        end

        it { expect { check_forced_decomposition }.to raise_error(/Separate CI database is not ready/) }

        context 'for SaaS', :saas do
          it { expect { check_forced_decomposition }.not_to raise_error }
        end

        context 'when env var GITLAB_ALLOW_SEPARATE_CI_DATABASE is true' do
          before do
            stub_env('GITLAB_ALLOW_SEPARATE_CI_DATABASE', 'true')
          end

          it { expect { check_forced_decomposition }.not_to raise_error }
        end

        context 'when env var GITLAB_ALLOW_SEPARATE_CI_DATABASE is false' do
          before do
            stub_env('GITLAB_ALLOW_SEPARATE_CI_DATABASE', 'false')
          end

          it { expect { check_forced_decomposition }.to raise_error(/Separate CI database is not ready/) }
        end
      end
    end
  end
end
