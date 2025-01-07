# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IssuablesCountForState do
  let(:finder) do
    double(:finder, current_user: nil, params: {}, count_by_state: { opened: 2, closed: 1 })
  end

  let(:project) { nil }
  let(:fast_fail) { nil }
  let(:counter) { described_class.new(finder, project, fast_fail: fast_fail) }

  describe 'project given' do
    let(:project) { build(:project) }

    it 'provides the project' do
      expect(counter.project).to eq(project)
    end
  end

  describe '.declarative_policy_class' do
    subject { described_class.declarative_policy_class }

    it { is_expected.to eq('IssuablePolicy') }
  end

  describe '#for_state_or_opened' do
    it 'returns the number of issuables for the given state' do
      expect(counter.for_state_or_opened(:closed)).to eq(1)
    end

    it 'returns the number of open issuables when no state is given' do
      expect(counter.for_state_or_opened).to eq(2)
    end

    it 'returns the number of open issuables when a nil value is given' do
      expect(counter.for_state_or_opened(nil)).to eq(2)
    end
  end

  describe '#[]' do
    it 'returns the number of issuables for the given state' do
      expect(counter[:closed]).to eq(1)
    end

    it 'casts valid states from Strings to Symbols' do
      expect(counter['closed']).to eq(1)
    end

    it 'returns 0 when using an invalid state name as a String' do
      expect(counter['kittens']).to be_zero
    end

    context 'fast_fail enabled' do
      let(:fast_fail) { true }

      it 'returns the expected value' do
        expect(counter[:closed]).to eq(1)
      end

      it 'returns -1 when the database times out' do
        expect(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

        expect(counter[:closed]).to eq(-1)
      end
    end
  end

  context 'when store_in_redis_cache is `true`', :clean_gitlab_redis_cache do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:cache_options) { { expires_in: 1.hour } }
    let(:threshold) { described_class::THRESHOLD }
    let(:states_count) { { opened: 1, closed: 1, all: 2 } }
    let(:params) { {} }

    subject { described_class.new(finder, fast_fail: true, store_in_redis_cache: true) }

    before do
      allow(finder).to receive(:count_by_state).and_return(states_count)
      allow_next_instance_of(described_class) do |counter|
        allow(counter).to receive(:parent_group).and_return(group)
      end
    end

    shared_examples 'calculating counts without caching' do
      it 'does not store in redis store' do
        expect(Rails.cache).not_to receive(:read)
        expect(finder).to receive(:count_by_state)
        expect(Rails.cache).not_to receive(:write)
        expect(subject[:all]).to eq(states_count[:all])
      end
    end

    shared_examples 'calculating counts for issuables' do
      it 'returns -1 for the requested state' do
        allow(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)
        expect(Rails.cache).not_to receive(:write)

        expect(subject[:all]).to eq(-1)
      end

      context 'when parent group is not present' do
        let(:group) { nil }

        it_behaves_like 'calculating counts without caching'
      end

      context 'when params include search filters' do
        let(:parent) { group }

        before do
          finder.params[:assignee_username] = [user.username, 'root']
        end

        it_behaves_like 'calculating counts without caching'
      end

      context 'when counts are stored in cache' do
        before do
          allow(Rails.cache).to receive(:read).with(cache_key, cache_options)
            .and_return({ opened: 1000, closed: 1000, all: 2000 })
        end

        it 'does not call finder count_by_state' do
          expect(finder).not_to receive(:count_by_state)

          expect(subject[:all]).to eq(2000)
        end
      end

      context 'when cache is empty' do
        context 'when state counts are under threshold' do
          let(:states_count) { { opened: 1, closed: 1, all: 2 } }

          it 'does not store state counts in cache' do
            expect(Rails.cache).to receive(:read).with(cache_key, cache_options)
            expect(finder).to receive(:count_by_state)
            expect(Rails.cache).not_to receive(:write)
            expect(subject[:all]).to eq(states_count[:all])
          end
        end

        context 'when state counts are over threshold' do
          let(:states_count) do
            { opened: threshold + 1, closed: threshold + 1, all: (threshold + 1) * 2 }
          end

          it 'stores state counts in cache' do
            expect(Rails.cache).to receive(:read).with(cache_key, cache_options)
            expect(finder).to receive(:count_by_state)
            expect(Rails.cache).to receive(:write).with(cache_key, states_count, cache_options)

            expect(subject[:all]).to eq((threshold + 1) * 2)
          end
        end
      end
    end

    context 'with Issues' do
      let(:finder) { IssuesFinder.new(user, params) }
      let(:cache_key) { ['group', group.id, 'issues'] }

      it_behaves_like 'calculating counts for issuables'
    end

    context 'with Work Items' do
      let(:finder) { ::WorkItems::WorkItemsFinder.new(user, params) }
      let(:cache_key) { ['group', group.id, 'work_items'] }

      it_behaves_like 'calculating counts for issuables'
    end

    context 'with Merge Requests' do
      let(:finder) { MergeRequestsFinder.new(user, params) }

      it_behaves_like 'calculating counts without caching'
    end
  end
end
