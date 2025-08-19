# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLimits, feature_category: :scalability do
  let(:worker_name) { 'Chaos::SleepWorker' }

  describe '.limits_for' do
    context 'with limit undefined in ApplicationSetting' do
      context 'when the worker name cannot be constantized' do
        let(:worker_name) { 'invalidworker' }

        it 'returns empty array' do
          expect(described_class.limits_for(worker_name)).to eq([])
        end
      end

      context 'when the worker does not extend ApplicationWorker' do
        let(:worker_name) { 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' }

        it 'returns empty array' do
          expect(described_class.limits_for(worker_name)).to eq([])
        end
      end

      context 'when the worker is non-urgent' do
        it 'returns catchall limits' do
          limits = described_class.limits_for(worker_name)
          expect(limits.map(&:name)).to include(:main_db_duration_limit_per_worker, :ci_db_duration_limit_per_worker,
            :sec_db_duration_limit_per_worker)
          expect(limits.map(&:threshold).uniq).to eq([described_class::DEFAULT_DB_DURATION_THRESHOLD_SECONDS])
        end
      end

      context 'when the worker matches a rule selector' do
        let(:worker_name) { 'PipelineProcessWorker' } # high urgency worker

        it 'returns limits' do
          limits = described_class.limits_for(worker_name)
          expect(limits.map(&:name)).to include(:main_db_duration_limit_per_worker, :ci_db_duration_limit_per_worker,
            :sec_db_duration_limit_per_worker)
          expect(limits.map(&:threshold).uniq).to eq([described_class::HIGH_URGENCY_DB_DURATION_THRESHOLD_SECONDS])
        end
      end
    end

    context 'when the worker does not match any selectors' do
      let(:rule) do
        {
          main_db_duration_limit_per_worker: {
            resource_key: 'db_main_duration_s',
            metadata: {
              db_config_name: 'main'
            },
            scopes: [
              'worker_name'
            ],
            rules: [
              {
                selector: Gitlab::SidekiqConfig::WorkerMatcher.new("worker_name=TestWorker"),
                threshold: 3000,
                interval: 60
              }
            ]
          }
        }
      end

      before do
        stub_const("#{described_class}::DEFAULT_SIDEKIQ_LIMITS", rule)
      end

      it 'returns no limits' do
        expect(described_class.limits_for(worker_name)).to be_empty
      end
    end

    context 'with limits defined in ApplicationSetting' do
      before do
        stub_application_setting(resource_usage_limits: {
          rules: [
            {
              name: "hi",
              rules: [
                {
                  interval: 60,
                  selector: "worker_name=Chaos::DbSleepWorker",
                  threshold: 5
                }
              ],
              scopes: [
                "worker_name"
              ],
              metadata: {
                db_config_name: "main"
              },
              resource_key: "db_main_duration_s"
            }
          ]
        })
      end

      context 'with worker matching the rules' do
        let(:worker_name) { 'Chaos::DbSleepWorker' }

        it 'follows limits in the setting' do
          limits = described_class.limits_for(worker_name)

          expect(limits.first.threshold).to eq(5)
        end
      end

      context 'with worker outside of the rules' do
        let(:worker_name) { 'SomeWorker' }

        it 'does not return a limit' do
          limits = described_class.limits_for(worker_name)

          expect(limits).to be_empty
        end
      end

      context 'when the limits cannot be parsed' do
        before do
          stub_application_setting(resource_usage_limits: {
            rules: "abcde"
          })
        end

        it 'tracks the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                             .with(a_kind_of(NoMethodError))

          described_class.limits_for(worker_name)
        end

        it 'returns limits from default' do
          limits = described_class.limits_for(worker_name)

          expect(limits.map(&:threshold).uniq).to eq([described_class::DEFAULT_DB_DURATION_THRESHOLD_SECONDS])
        end

        context 'when selector cannot be parsed' do
          before do
            stub_application_setting(resource_usage_limits: {
              rules: [
                {
                  name: "hi",
                  rules: [
                    {
                      interval: 60,
                      selector: "foobar", # invalid selector here
                      threshold: 5
                    }
                  ],
                  scopes: [
                    "worker_name"
                  ],
                  metadata: {
                    db_config_name: "main"
                  },
                  resource_key: "db_main_duration_s"
                }
              ]
            })
          end

          it 'tracks the error' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                               .with(a_kind_of(Gitlab::SidekiqConfig::WorkerMatcher::InvalidTerm))

            described_class.limits_for(worker_name)
          end

          it 'returns limits from default' do
            limits = described_class.limits_for(worker_name)

            expect(limits.map(&:threshold).uniq).to eq([described_class::DEFAULT_DB_DURATION_THRESHOLD_SECONDS])
          end
        end
      end
    end
  end
end
