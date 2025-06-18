# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::Framework::ProgressTracking, :clean_gitlab_redis_shared_state, feature_category: :importers do
  subject(:klass) do
    Class.new do
      include ::Import::Framework::ProgressTracking

      def self.name
        'Klass'
      end
    end.new
  end

  before do
    stub_const('Klass', klass)

    allow(klass).to receive_message_chain(:importable, :root_ancestor)
  end

  describe '#with_progress_tracking' do
    it 'saves processed entry' do
      klass.with_progress_tracking(scope: { foo: :bar }, data: 'baz') { true }

      expect(Gitlab::Cache::Import::Caching.values_from_set('progress-tracking:klass:foo:bar')).to match_array('baz')
    end

    context 'when entry is already processed' do
      it 'returns true without saving already processed entry' do
        Gitlab::Cache::Import::Caching.set_add('progress-tracking:klass:foo:bar', 'baz')

        expect(Gitlab::Cache::Import::Caching).not_to receive(:set_add)

        klass.with_progress_tracking(scope: { foo: :bar }, data: 'baz') { true }
      end
    end
  end

  describe '#save_processed_entry' do
    it 'saves processed entry' do
      klass.save_processed_entry(scope: { foo: :bar }, data: 'baz')

      expect(Gitlab::Cache::Import::Caching.values_from_set('progress-tracking:klass:foo:bar')).to match_array('baz')
    end
  end

  describe '#processed_entry?' do
    it 'returns true for processed entry' do
      klass.save_processed_entry(scope: { foo: :bar }, data: 'baz')

      expect(klass.processed_entry?(scope: { foo: :bar }, data: 'baz')).to be(true)
    end

    it 'returns false for non-processed entry' do
      expect(klass.processed_entry?(scope: { foo: :bar }, data: 'baz')).to be(false)
    end
  end
end
