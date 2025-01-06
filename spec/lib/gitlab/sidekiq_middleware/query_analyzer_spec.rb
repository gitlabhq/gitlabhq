# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::QueryAnalyzer, query_analyzers: false do
  describe 'the PreventCrossDatabaseModification' do
    describe '#call' do
      let(:worker) { double(:worker) }
      let(:job) { { 'jid' => 'job123' } }
      let(:queue) { 'some-queue' }
      let(:middleware) { described_class.new }

      def do_queries; end

      subject { middleware.call(worker, job, queue) { do_queries } }

      context 'when there is a cross modification' do
        def do_queries
          Project.transaction do
            Project.where(id: -1).update_all(id: -1)
            ::Ci::Pipeline.where(id: -1).update_all(id: -1)
          end
        end

        it 'detects cross modifications and tracks exception',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/507880' do
          expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          subject
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
        def do_queries
          Project.transaction do
            Project.where(id: -1).update_all(id: -1)
            Namespace.where(id: -1).update_all(id: -1)
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
