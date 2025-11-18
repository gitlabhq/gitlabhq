# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetentionPolicies::PipelineDeletionCutoffCache, :freeze_time, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project, ci_delete_pipelines_in_seconds: 1.day.to_i) }
  let(:cutoff_cache) { described_class.new(project: project) }
  let(:base_time) { Time.current }
  let(:statuses) { Ci::Pipeline::COMPLETED_WITH_MANUAL_STATUSES + ['other'] }

  let(:status_timestamps) do
    statuses.each_with_index.to_h { |status, index| [status, index.hours.before(base_time)] }
  end

  describe '#write' do
    let(:values) { status_timestamps }

    context 'with valid values' do
      context 'when storing data' do
        it 'stores the timestamps as JSON in Redis with correct key and expiration' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).to receive(:set)
              .with(anything, anything, ex: described_class::REDIS_KEY_TTL)
              .and_call_original
          end

          expect(cutoff_cache.write(values)).to eq('OK')
        end

        it 'stores all status timestamps at once' do
          cutoff_cache.write(values)

          result = cutoff_cache.read

          expect(result).to match(statuses.index_with { |status| status_timestamps[status] })
        end
      end

      context 'when replacing existing data' do
        let(:values) do
          {
            'success' => 10.hours.ago,
            'failed' => 11.hours.ago
          }
        end

        let(:new_values) { status_timestamps }

        before do
          cutoff_cache.write(values)
        end

        it 'replaces all existing data when writing new values', :aggregate_failures do
          expect { cutoff_cache.write(new_values) }
            .to change { cutoff_cache.read }
            .from(values)
            .to(new_values)
        end
      end

      context 'when handling partial updates' do
        let(:statuses) { %w[success failed] }
        let(:values) { status_timestamps.slice(*statuses) }

        before do
          cutoff_cache.write(values)
        end

        it 'stores only the provided status timestamps' do
          expect(cutoff_cache.read).to match(statuses.index_with { |status| status_timestamps[status] })
        end
      end
    end

    context 'with nil values' do
      let(:values) do
        {
          'success' => base_time,
          'failed' => base_time + 1.hour,
          'canceled' => nil,
          'skipped' => base_time + 2.hours
        }
      end

      before do
        cutoff_cache.write(values)
      end

      it 'filters out nil values' do
        expect(cutoff_cache.read.keys).to contain_exactly('success', 'failed', 'skipped')
      end
    end

    context 'with empty hash' do
      it 'returns nil and does not store anything' do
        expect(cutoff_cache.write({})).to be_nil
        expect(cutoff_cache.read).to eq({})
      end
    end
  end

  describe '#read' do
    subject(:read) { cutoff_cache.read }

    it { is_expected.to eq({}) }

    context 'when redis has values for project' do
      before do
        cutoff_cache.write(status_timestamps)
      end

      it 'returns all cached timestamps as Time objects' do
        is_expected.to eq(status_timestamps)
      end
    end

    context 'when redis contains invalid JSON' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(cutoff_cache.send(:key), 'invalid json{', ex: described_class::REDIS_KEY_TTL)
        end
      end

      it { is_expected.to eq({}) }
    end

    context 'when project retention config is updated' do
      where(:to) do
        [
          nil,
          14.days.to_i
        ]
      end

      with_them do
        before do
          cutoff_cache.write(status_timestamps)
        end

        it 'invalidates cache' do
          expect { project.update!(ci_delete_pipelines_in_seconds: to) }
            .to change { cutoff_cache.read }.from(status_timestamps).to({})
        end
      end
    end
  end

  describe '#clear' do
    subject(:clear) { cutoff_cache.clear }

    context 'when key exists with data' do
      before do
        cutoff_cache.write(status_timestamps)
      end

      it 'removes all data from Redis' do
        expect { clear }.to change { cutoff_cache.read }.from(status_timestamps).to({})
      end

      it 'removes the key entirely from Redis' do
        Gitlab::Redis::SharedState.with do |redis|
          expect { clear }.to change { redis.exists?(cutoff_cache.send(:key)) }.to(false)
        end
      end
    end

    context 'when key does not exist' do
      it { expect { clear }.not_to raise_error }
    end
  end

  context 'with multiple projects' do
    let_it_be(:project2, freeze: true) { create(:project, ci_delete_pipelines_in_seconds: 7.days.to_i) }
    let(:cutoff_cache2) { described_class.new(project: project2) }
    let(:project1_values) { status_timestamps }
    let(:project2_values) { status_timestamps.transform_values { |timestamp| 1.day.before(timestamp) } }

    before do
      cutoff_cache.write(project1_values)
      cutoff_cache2.write(project2_values)
    end

    it 'handles multiple projects correctly without data collision', :aggregate_failures do
      project1_data = cutoff_cache.read
      project2_data = cutoff_cache2.read

      expect(project1_data).to eq(project1_values)
      expect(project2_data).to eq(project2_values)
      expect(project1_data).not_to eq(project2_data)
    end
  end
end
