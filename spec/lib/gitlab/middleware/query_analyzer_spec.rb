# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::QueryAnalyzer, query_analyzers: false, feature_category: :database do
  describe 'recording the HTTP request method', :request_store do
    let(:app) { double(:app) }
    let(:middleware) { described_class.new(app) }
    let(:env) { { 'REQUEST_METHOD' => 'GET' } }

    it 'makes the request method readable before the analyzers run' do
      expect(app).to receive(:call) do
        expect(described_class.http_request_method).to eq('GET')
      end

      middleware.call(env)
    end
  end

  describe '.http_request_method' do
    it 'returns nil when no request method was recorded' do
      expect(described_class.http_request_method).to be_nil
    end
  end

  describe 'the PreventWritesOnGet', :request_store do
    let(:app) { double(:app) }
    let(:middleware) { described_class.new(app) }
    let(:env) { { 'REQUEST_METHOD' => request_method } }
    let(:analyzer_logger) { ::Gitlab::Database::QueryAnalyzers::PreventWritesOnGet::Logger }

    subject { middleware.call(env) }

    before do
      allow(app).to receive(:call) do
        Project.where(id: -1).update_all(id: -1)
      end

      allow(::Gitlab::Database::QueryAnalyzers::PreventWritesOnGet).to receive(:suppressed?).and_return(false)
      allow(::Feature::FlipperFeature).to receive(:table_exists?).and_return(true)
    end

    context 'when a GET request writes to the database' do
      let(:request_method) { 'GET' }

      it 'logs the violation' do
        expect(analyzer_logger).to receive(:warn).with(a_hash_including(message: 'write_on_get_detected'))

        subject
      end

      context 'when the detect_writes_on_get flag is disabled' do
        before do
          stub_feature_flags(detect_writes_on_get: false)
        end

        it 'does not log' do
          expect(analyzer_logger).not_to receive(:warn)

          subject
        end
      end
    end

    context 'when a POST request writes to the database' do
      let(:request_method) { 'POST' }

      it 'does not log' do
        expect(analyzer_logger).not_to receive(:warn)

        subject
      end
    end
  end

  describe 'the PreventCrossDatabaseModification' do
    describe '#call' do
      let(:app) { double(:app) }
      let(:middleware) { described_class.new(app) }
      let(:env) { {} }

      subject { middleware.call(env) }

      context 'when there is a cross modification' do
        before do
          allow(app).to receive(:call) do
            Project.transaction do
              Project.where(id: -1).update_all(id: -1)
              ::Ci::Pipeline.where(id: -1).update_all(id: -1)
            end
          end
        end

        it 'detects cross modifications and tracks exception',
          quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/16820' do
          expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect { subject }.not_to raise_error
        end

        context 'when the detect_cross_database_modification is disabled' do
          before do
            stub_feature_flags(detect_cross_database_modification: false)
          end

          it 'does not detect cross modifications' do
            expect(::Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

            subject
          end
        end
      end

      context 'when there is no cross modification' do
        before do
          allow(app).to receive(:call) do
            Project.transaction do
              Project.where(id: -1).update_all(id: -1)
              Namespace.where(id: -1).update_all(id: -1)
            end
          end
        end

        it 'does not log anything' do
          expect(::Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          subject
        end
      end
    end
  end
end
