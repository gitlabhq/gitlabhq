# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DiscussionsDiff::HighlightCache, :clean_gitlab_redis_cache do
  describe '#write_multiple' do
    it 'sets multiple keys serializing content as JSON' do
      mapping = {
        3 => [
          {
            text: 'foo',
            type: 'new',
            index: 2,
            old_pos: 10,
            new_pos: 11,
            line_code: 'xpto',
            rich_text: '<blips>blops</blips>'
          },
          {
            text: 'foo',
            type: 'new',
            index: 3,
            old_pos: 11,
            new_pos: 12,
            line_code: 'xpto',
            rich_text: '<blops>blips</blops>'
          }
        ]
      }

      described_class.write_multiple(mapping)

      mapping.each do |key, value|
        full_key = described_class.cache_key_for(key)
        found = Gitlab::Redis::Cache.with { |r| r.get(full_key) }

        expect(found).to eq(value.to_json)
      end
    end
  end

  describe '#read_multiple' do
    it 'reads multiple keys and serializes content into Gitlab::Diff::Line objects' do
      mapping = {
        3 => [
          {
            text: 'foo',
            type: 'new',
            index: 2,
            old_pos: 11,
            new_pos: 12,
            line_code: 'xpto',
            rich_text: '<blips>blops</blips>'
          },
          {
            text: 'foo',
            type: 'new',
            index: 3,
            old_pos: 10,
            new_pos: 11,
            line_code: 'xpto',
            rich_text: '<blips>blops</blips>'
          }
        ]
      }

      described_class.write_multiple(mapping)

      found = described_class.read_multiple(mapping.keys)

      expect(found.size).to eq(1)
      expect(found.first.size).to eq(2)
      expect(found.first).to all(be_a(Gitlab::Diff::Line))
    end

    it 'returns nil when cached key is not found' do
      mapping = {
        3 => [
          {
            text: 'foo',
            type: 'new',
            index: 2,
            old_pos: 11,
            new_pos: 12,
            line_code: 'xpto',
            rich_text: '<blips>blops</blips>'
          }
        ]
      }

      described_class.write_multiple(mapping)

      found = described_class.read_multiple([2, 3])

      expect(found.size).to eq(2)

      expect(found.first).to eq(nil)
      expect(found.second.size).to eq(1)
      expect(found.second).to all(be_a(Gitlab::Diff::Line))
    end
  end
end
