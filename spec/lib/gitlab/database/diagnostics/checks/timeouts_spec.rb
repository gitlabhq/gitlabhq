# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Checks::Timeouts, feature_category: :database do
  describe '#execute' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    let(:statement_timeout) { 60_000 }
    let(:statement_timeout_default) { 0 }

    let(:setting_rows) do
      [
        setting_row('statement_timeout', statement_timeout, statement_timeout_default),
        setting_row('lock_timeout', 0, 0),
        setting_row('idle_in_transaction_session_timeout', 0, 0)
      ]
    end

    let(:override_rows) { [] }

    subject(:result) { described_class.new(connection).execute }

    def setting_row(name, value, default_value, source: 'session', sourcefile: nil, sourceline: nil)
      {
        'name' => name,
        'setting' => value.to_s,
        'unit' => 'ms',
        'source' => source,
        'sourcefile' => sourcefile,
        'sourceline' => sourceline,
        'reset_val' => default_value.to_s
      }
    end

    before do
      allow(connection).to receive(:quote) { |name| "'#{name}'" }
      allow(connection).to receive(:select_all).with(formatted(described_class::SETTINGS_SQL))
        .and_return(setting_rows)
      allow(connection).to receive(:select_all).with(formatted(described_class::OVERRIDES_SQL))
        .and_return(override_rows)
    end

    def formatted(sql)
      format(sql, names: described_class::SETTING_NAMES.map { |name| "'#{name}'" }.join(', '))
    end

    describe 'settings' do
      it 'returns every setting keyed in SETTING_NAMES order' do
        expect(result[:settings].keys).to eq(described_class::SETTING_NAMES)
      end

      it 'casts the session and cluster default values to integers' do
        expect(result[:settings]['statement_timeout']).to eq(
          value: 60_000,
          default_value: 0,
          unit: 'ms',
          source: 'session',
          source_location: nil
        )
      end

      context 'when a setting is missing from pg_settings' do
        let(:setting_rows) { [setting_row('statement_timeout', 60_000, 0)] }

        it 'skips it instead of reporting a blank row' do
          expect(result[:settings].keys).to contain_exactly('statement_timeout')
        end
      end

      context 'when the value comes from a configuration file' do
        let(:setting_rows) do
          [setting_row('statement_timeout', 60_000, 60_000,
            source: 'configuration file', sourcefile: '/etc/postgresql/postgresql.conf', sourceline: 750)]
        end

        it 'joins the file and line into a single location' do
          expect(result[:settings]['statement_timeout'][:source_location])
            .to eq('/etc/postgresql/postgresql.conf:750')
        end
      end
    end

    describe 'findings' do
      subject(:findings) { result[:findings] }

      context 'when the session value is within the recommended maximum' do
        let(:statement_timeout) { 60_000 }
        let(:statement_timeout_default) { 60_000 }

        it 'returns no findings and no severity', :aggregate_failures do
          expect(findings).to be_empty
          expect(result[:severity]).to be_nil
          expect(result[:counts]).to eq({})
        end
      end

      context 'when the session value is unlimited' do
        let(:statement_timeout) { 0 }

        it 'returns a single error, without also reporting the cluster default', :aggregate_failures do
          expect(findings.pluck(:code)).to contain_exactly('statement_timeout_unlimited')
          expect(result[:severity]).to eq('error')
          expect(result[:counts]).to eq({ 'error' => 1 })
        end
      end

      context 'when the session value is above the recommended maximum' do
        let(:statement_timeout) { 300_000 }
        let(:statement_timeout_default) { 60_000 }

        it 'returns a warning that names both values' do
          expect(findings.pluck(:code)).to contain_exactly('statement_timeout_above_maximum')
          expect(findings.first[:message]).to include('300000 ms').and include('60000 ms')
        end
      end

      context 'when only the cluster default is unlimited' do
        it 'returns a warning about the sessions GitLab does not configure', :aggregate_failures do
          expect(findings.pluck(:code)).to contain_exactly('statement_timeout_unlimited_by_default')
          expect(result[:severity]).to eq('warning')
        end

        context 'when a role or database sets statement_timeout' do
          let(:override_rows) do
            [{ 'database_name' => nil, 'role_name' => 'gitlab', 'name' => 'statement_timeout', 'value' => '0' }]
          end

          it 'returns no findings, because reset_val no longer shows what other roles get' do
            expect(findings).to be_empty
          end
        end

        context 'when a role or database sets only another timeout' do
          let(:override_rows) do
            [{ 'database_name' => nil, 'role_name' => 'gitlab', 'name' => 'lock_timeout', 'value' => '5s' }]
          end

          it 'still returns the warning' do
            expect(findings.pluck(:code)).to contain_exactly('statement_timeout_unlimited_by_default')
          end
        end
      end

      context 'when statement_timeout is missing from pg_settings' do
        let(:setting_rows) { [setting_row('lock_timeout', 0, 0)] }

        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when lock_timeout and idle_in_transaction_session_timeout are unlimited' do
        let(:statement_timeout) { 60_000 }
        let(:statement_timeout_default) { 60_000 }

        it 'does not judge them' do
          expect(findings).to be_empty
        end
      end
    end

    describe 'overrides' do
      let(:override_rows) do
        [
          { 'database_name' => nil, 'role_name' => nil, 'name' => 'statement_timeout', 'value' => '90s' },
          { 'database_name' => 'gitlabhq', 'role_name' => 'gitlab', 'name' => 'lock_timeout', 'value' => '5s' }
        ]
      end

      it 'returns each role and database default, keeping nil for "applies to all"' do
        expect(result[:overrides]).to eq([
          { database_name: nil, role_name: nil, name: 'statement_timeout', value: '90s' },
          { database_name: 'gitlabhq', role_name: 'gitlab', name: 'lock_timeout', value: '5s' }
        ])
      end

      context 'when no role or database sets a timeout' do
        let(:override_rows) { [] }

        it 'returns an empty list' do
          expect(result[:overrides]).to eq([])
        end
      end
    end
  end

  describe 'the SQL it runs', :aggregate_failures do
    let(:connection) { ApplicationRecord.connection }

    it 'reads the timeout settings from the live database' do
      result = described_class.new(connection).execute

      expect(result[:settings].keys).to include('statement_timeout')
      expect(result[:settings]['statement_timeout'][:unit]).to eq('ms')
      expect(result[:overrides]).to be_an(Array)
    end
  end
end
