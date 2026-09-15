# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:click_house:schema', :click_house, feature_category: :database do
  include ClickHouseSchemaHelpers

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/click_house/schema'
  end

  describe 'load' do
    context 'when DISABLE_WEBMOCK IS NOT SET' do
      before do
        # For what is being tested we do not need schema loaded on each database
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({})
      end

      it 'does not allow real HTTP requests' do
        expect(WebMock).not_to receive(:allow_net_connect!)

        run_rake_task('gitlab:clickhouse:schema:load:main')
      end

      context 'when DISABLE_WEBMOCK IS SET' do
        before do
          stub_env('DISABLE_WEBMOCK', 1)
        end

        it 'allows real HTTP requests' do
          expect(WebMock).to receive(:allow_net_connect!)

          run_rake_task('gitlab:clickhouse:schema:load:main')
        end

        context 'and not in test environment' do
          before do
            allow(Rails.env).to receive(:test?).and_return(false)
          end

          it 'does not allow real HTTP requests' do
            expect(WebMock).not_to receive(:allow_net_connect!)

            run_rake_task('gitlab:clickhouse:schema:load:main')
          end
        end
      end
    end
  end

  describe 'dump' do
    let(:schema_sql_path) { Rails.root.join('db/click_house/main.sql') }

    before do
      stub_env('ENABLE_CLICKHOUSE_DB_DUMP', 'true')
      allow(File).to receive(:writable?).and_call_original
      allow(File).to receive(:writable?).with(schema_sql_path).and_return(false)
    end

    it 'dumps the schema cache in test environment' do
      expect(ClickHouse::SchemaCache).to receive(:dump).with(instance_of(ClickHouse::Connection), :main)

      run_rake_task('gitlab:clickhouse:schema:dump:main')
    end

    context 'when in development environment' do
      before do
        allow(Rails.env).to receive_messages(development?: true, test?: false)
      end

      it 'dumps the schema cache' do
        expect(ClickHouse::SchemaCache).to receive(:dump).with(instance_of(ClickHouse::Connection), :main)

        run_rake_task('gitlab:clickhouse:schema:dump:main')
      end
    end

    context 'when in production environment' do
      before do
        allow(Rails.env).to receive_messages(development?: false, test?: false)
      end

      it 'does not dump the schema cache' do
        expect(ClickHouse::SchemaCache).not_to receive(:dump)

        run_rake_task('gitlab:clickhouse:schema:dump:main')
      end
    end
  end
end
