# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse, feature_category: :database do
  subject { described_class }

  context 'when ClickHouse is not configured' do
    it { is_expected.not_to be_configured }

    it { is_expected.not_to be_enabled_for_analytics }

    it { is_expected.not_to be_globally_enabled_for_analytics }

    context 'and is enabled for analytics on settings' do
      before do
        stub_application_setting(use_clickhouse_for_analytics: true)
      end

      it { is_expected.not_to be_enabled_for_analytics }

      it { is_expected.not_to be_globally_enabled_for_analytics }
    end
  end

  context 'when ClickHouse is configured', :click_house do
    it { is_expected.to be_configured }

    it { is_expected.not_to be_enabled_for_analytics }

    it { is_expected.not_to be_globally_enabled_for_analytics }

    context 'and enabled for analytics on settings' do
      before do
        stub_application_setting(use_clickhouse_for_analytics: true)
      end

      it { is_expected.to be_enabled_for_analytics }

      it { is_expected.to be_globally_enabled_for_analytics }
    end
  end

  describe '.siphon_enabled?' do
    let(:table_name) { 'duo_workflows_workflows' }

    context 'when ClickHouse is not configured' do
      it 'returns false without querying ClickHouse' do
        expect(::ClickHouse::Client).not_to receive(:select)

        expect(described_class.siphon_enabled?).to be(false)
        expect(described_class.siphon_enabled?(table_name)).to be(false)
      end
    end

    context 'when ClickHouse is configured', :click_house do
      context 'when Siphon has not replicated anything' do
        it { expect(described_class.siphon_enabled?).to be(false) }

        it { expect(described_class.siphon_enabled?(table_name)).to be(false) }
      end

      context 'when Siphon has replicated the table' do
        before do
          clickhouse_fixture(:siphon_internal_events, [{ postgresql_schema: 'public', postgresql_table: table_name }])
        end

        it 'is enabled globally and for that table' do
          expect(described_class.siphon_enabled?).to be(true)
          expect(described_class.siphon_enabled?(table_name)).to be(true)
          expect(described_class.siphon_enabled?('issues')).to be(false)
        end

        it 'caches a positive per-table result' do
          expect(described_class.siphon_enabled?(table_name)).to be(true)

          expect(::ClickHouse::Client).not_to receive(:select)

          expect(described_class.siphon_enabled?(table_name)).to be(true)
        end

        it 'lets a cached per-table result short-circuit the global check' do
          expect(described_class.siphon_enabled?(table_name)).to be(true)

          expect(::ClickHouse::Client).not_to receive(:select)

          expect(described_class.siphon_enabled?).to be(true)
        end

        it 'does not cache a negative result' do
          expect(described_class.siphon_enabled?('issues')).to be(false)

          expect(::ClickHouse::Client).to receive(:select).and_call_original

          expect(described_class.siphon_enabled?('issues')).to be(false)
        end
      end

      context 'when the ClickHouse query fails' do
        [::ClickHouse::Client::Error, Net::OpenTimeout].each do |error_class|
          context "with #{error_class}" do
            let(:error) { error_class.new('boom') }

            before do
              allow(::ClickHouse::Client).to receive(:select).and_raise(error)
            end

            it 'logs the exception and returns false without caching' do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(error).twice

              expect(described_class.siphon_enabled?(table_name)).to be(false)
              expect(described_class.siphon_enabled?(table_name)).to be(false)
            end
          end
        end
      end
    end
  end
end
