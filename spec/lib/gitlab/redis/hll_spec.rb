# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::HLL, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  let(:expiry) { 1.day }

  describe '.add' do
    context 'when checking key format' do
      context 'for invalid keys' do
        where(:metric_key, :value) do
          'test'           | 1
          'test-{metric'   | 1
          'test-{metric}}' | 1
        end

        with_them do
          it 'raise an error when using an invalid key format' do
            expect { described_class.add(key: metric_key, value: value, expiry: expiry) }.to raise_error(Gitlab::Redis::HLL::KeyFormatError)
          end
        end
      end

      context 'for valid keys' do
        where(:metric_key, :value) do
          'test-{metric}'                       | 1
          'test-{metric}-1'                     | 1
          'test:{metric}-1'                     | 1
          '2020-216-{project_action}'           | 1
          'i_{analytics}_dev_ops_score-2020-32' | 1
          'i_{analytics}_event:[prop:a,attr:2]' | 1
        end

        with_them do
          it "doesn't raise error when having correct format" do
            expect { described_class.add(key: metric_key, value: value, expiry: expiry) }.not_to raise_error
          end
        end
      end
    end

    context 'when adding entries' do
      let(:metric) { 'test-{metric}' }

      it 'supports single value' do
        track_event(metric, 1)

        expect(count_unique_events([metric])).to eq(1)
      end

      it 'supports multiple values' do
        stub_const("#{described_class.name}::HLL_BATCH_SIZE", 2)

        track_event(metric, [1, 2, 3, 4, 5])

        expect(count_unique_events([metric])).to eq(5)
      end
    end
  end

  describe '.count' do
    let(:event_2020_32) { '2020-32-{expand_vulnerabilities}' }
    let(:event_2020_33) { '2020-33-{expand_vulnerabilities}' }
    let(:event_2020_34) { '2020-34-{expand_vulnerabilities}' }

    let(:entity1) { 'user_id_1' }
    let(:entity2) { 'user_id_2' }
    let(:entity3) { 'user_id_3' }
    let(:entity4) { 'user_id_4' }

    before do
      track_event(event_2020_32, entity1)
      track_event(event_2020_32, entity1)
      track_event(event_2020_32, entity2)
      track_event(event_2020_32, entity3)

      track_event(event_2020_33, entity3)
      track_event(event_2020_33, entity3)

      track_event(event_2020_34, entity3)
      track_event(event_2020_34, entity2)
    end

    it 'has 3 distinct users for weeks 32, 33, 34' do
      unique_counts = count_unique_events([event_2020_32, event_2020_33, event_2020_34])

      expect(unique_counts).to eq(3)
    end

    it 'has 3 distinct users for weeks 32, 33' do
      unique_counts = count_unique_events([event_2020_32, event_2020_33])

      expect(unique_counts).to eq(3)
    end

    it 'has 2 distinct users for weeks 33, 34' do
      unique_counts = count_unique_events([event_2020_33, event_2020_34])

      expect(unique_counts).to eq(2)
    end

    it 'has one distinct user for week 33' do
      unique_counts = count_unique_events([event_2020_33])

      expect(unique_counts).to eq(1)
    end

    it 'has 4 distinct users when one different user has an action on week 34' do
      track_event(event_2020_34, entity4, 29.days)
      unique_counts = count_unique_events([event_2020_32, event_2020_33, event_2020_34])

      expect(unique_counts).to eq(4)
    end
  end

  def track_event(key, value, expiry = 1.day)
    described_class.add(key: key, value: value, expiry: expiry)
  end

  def count_unique_events(keys)
    described_class.count(keys: keys)
  end
end
