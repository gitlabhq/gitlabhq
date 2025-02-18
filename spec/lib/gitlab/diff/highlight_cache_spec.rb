# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::HighlightCache, :clean_gitlab_redis_cache, feature_category: :source_code_management do
  let_it_be(:merge_request) { create(:merge_request_with_diffs) }

  let(:diff_hash) do
    { ".gitignore-false-false-false" =>
      [{ line_code: nil, rich_text: nil, text: "@@ -17,3 +17,4 @@ rerun.txt", type: "match", index: 0, old_pos: 17, new_pos: 17 },
       { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_17_17",
         rich_text: " <span id=\"LC17\" class=\"line\" lang=\"plaintext\">pickle-email-*.html</span>\n",
         text: " pickle-email-*.html",
         type: nil,
         index: 1,
         old_pos: 17,
         new_pos: 17 },
       { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_18_18",
         rich_text: " <span id=\"LC18\" class=\"line\" lang=\"plaintext\">.project</span>\n",
         text: " .project",
         type: nil,
         index: 2,
         old_pos: 18,
         new_pos: 18 },
       { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_19_19",
         rich_text: " <span id=\"LC19\" class=\"line\" lang=\"plaintext\">config/initializers/secret_token.rb</span>\n",
         text: " config/initializers/secret_token.rb",
         type: nil,
         index: 3,
         old_pos: 19,
         new_pos: 19 },
       { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_20_20",
         rich_text: "+<span id=\"LC20\" class=\"line\" lang=\"plaintext\">.DS_Store</span>",
         text: "+.DS_Store",
         type: "new",
         index: 4,
         old_pos: 20,
         new_pos: 20 }] }
  end

  let(:cache_key) { cache.key }

  subject(:cache) { described_class.new(merge_request.diffs) }

  describe '#decorate' do
    # Manually creates a Diff::File object to avoid triggering the cache on
    #   the FileCollection::MergeRequestDiff
    #
    let(:diff_file) do
      diffs = merge_request.diffs
      raw_diff = diffs.diffable.raw_diffs(diffs.diff_options.merge(paths: ['CHANGELOG'])).first
      Gitlab::Diff::File.new(
        raw_diff,
        repository: diffs.project.repository,
        diff_refs: diffs.diff_refs,
        fallback_diff_refs: diffs.fallback_diff_refs
      )
    end

    before do
      cache.write_if_empty
      cache.decorate(diff_file)
    end

    it 'does not calculate highlighting when reading from cache' do
      expect_any_instance_of(Gitlab::Diff::Highlight).not_to receive(:highlight)

      diff_file.highlighted_diff_lines
    end

    it 'assigns highlighted diff lines to the DiffFile' do
      expect(diff_file.highlighted_diff_lines.size).to be > 5
    end

    it 'assigns highlighted diff lines which rich_text are HTML-safe' do
      rich_texts = diff_file.highlighted_diff_lines.map(&:rich_text)

      expect(rich_texts).to all(be_html_safe)
    end

    context "when diff_file is uncached due to default_max_patch_bytes change" do
      before do
        expect(cache).to receive(:read_file).at_least(:once).and_return([])

        # Stub out the application's default and current patch size limits. We
        #   want them to be different, and the diff file to be sized between
        #   the 2 values.
        #
        diff_file_size_kb = (diff_file.diff.diff.bytesize * 10)

        stub_const("#{diff_file.diff.class}::DEFAULT_MAX_PATCH_BYTES", diff_file_size_kb - 1)
        expect(diff_file.diff.class).to receive(:patch_safe_limit_bytes).and_return(diff_file_size_kb + 1)
        expect(diff_file.diff.class)
          .to receive(:patch_safe_limit_bytes)
          .with(diff_file.diff.class::DEFAULT_MAX_PATCH_BYTES)
          .and_call_original
      end

      it "manually writes highlighted lines to the cache" do
        expect(cache).to receive(:write_to_redis_hash).and_call_original

        cache.decorate(diff_file)
      end

      it "assigns highlighted diff lines to the DiffFile" do
        expect(diff_file.highlighted_diff_lines.size).to be > 5

        cache.decorate(diff_file)
      end
    end
  end

  shared_examples 'caches missing entries' do
    it 'filters the key/value list of entries to be caches for each invocation' do
      expect(cache).to receive(:write_to_redis_hash)
        .with(hash_including(*paths))
        .once
        .and_call_original

      2.times { cache.write_if_empty }
    end

    it 'reads from cache once' do
      expect(cache).to receive(:read_cache).once.and_call_original

      cache.write_if_empty
    end

    it 'refreshes TTL of the key on read' do
      cache.write_if_empty

      time_until_expire = 30.minutes

      Gitlab::Redis::Cache.with do |redis|
        # Emulate that a key is going to expire soon
        redis.expire(cache.key, time_until_expire)

        expect(redis.ttl(cache.key)).to be <= time_until_expire

        cache.send(:read_cache)

        expect(redis.ttl(cache.key)).to be > time_until_expire
        expect(redis.ttl(cache.key)).to be_within(1.minute).of(described_class::EXPIRATION)
      end
    end
  end

  describe '#write_if_empty' do
    it_behaves_like 'caches missing entries' do
      let(:paths) { merge_request.diffs.raw_diff_files.select(&:text?).map(&:file_path) }
    end

    it 'updates memory usage metrics if Redis version >= 4' do
      allow_next_instance_of(Redis) do |redis|
        allow(redis).to receive(:info).and_return({ "redis_version" => "4.0.0" })

        expect(described_class.gitlab_redis_diff_caching_memory_usage_bytes)
          .to receive(:observe).and_call_original

        cache.send(:write_to_redis_hash, diff_hash)
      end
    end

    it 'does not update memory usage metrics if Redis version < 4' do
      allow_next_instance_of(Redis) do |redis|
        allow(redis).to receive(:info).and_return({ "redis_version" => "3.0.0" })

        expect(described_class.gitlab_redis_diff_caching_memory_usage_bytes)
          .not_to receive(:observe)

        cache.send(:write_to_redis_hash, diff_hash)
      end
    end

    context 'different diff_collections for the same diffable' do
      before do
        cache.write_if_empty
      end

      it 'writes an uncached files in the collection to the same redis hash' do
        Gitlab::Redis::Cache.with { |r| r.hdel(cache_key, "files/whitespace") }

        expect { cache.write_if_empty }
          .to change { Gitlab::Redis::Cache.with { |r| r.hgetall(cache_key) } }
      end
    end

    context 'when cache initialized with MergeRequestDiffBatch' do
      let(:merge_request_diff_batch) do
        Gitlab::Diff::FileCollection::MergeRequestDiffBatch.new(
          merge_request.merge_request_diff,
          1,
          10,
          diff_options: nil)
      end

      it_behaves_like 'caches missing entries' do
        let(:cache) { described_class.new(merge_request_diff_batch) }
        let(:paths) { merge_request_diff_batch.raw_diff_files.select(&:text?).map(&:file_path) }
      end
    end
  end

  describe '#write_to_redis_hash' do
    it 'creates or updates a Redis hash' do
      expect { cache.send(:write_to_redis_hash, diff_hash) }
        .to change { Gitlab::Redis::Cache.with { |r| r.hgetall(cache_key) } }
    end

    context 'when diff contains unsupported characters' do
      let(:diff_hash) { { 'README' => [{ line_code: nil, rich_text: nil, text: [0xff, 0xfe, 0x0, 0x23].pack("c*"), type: "match", index: 0, old_pos: 17, new_pos: 17 }] } }

      it 'does not update the cache' do
        expect { cache.send(:write_to_redis_hash, diff_hash) }
          .not_to change { Gitlab::Redis::Cache.with { |r| r.hgetall(cache_key) } }
      end
    end
  end

  describe '#clear' do
    it 'clears cache' do
      Gitlab::Redis::Cache.with { |r| expect(r).to receive(:del).with(cache_key) }

      cache.clear
    end
  end

  describe "GZip usage" do
    let(:diff_file) do
      diffs = merge_request.diffs
      raw_diff = diffs.diffable.raw_diffs(diffs.diff_options.merge(paths: ['CHANGELOG'])).first
      Gitlab::Diff::File.new(
        raw_diff,
        repository: diffs.project.repository,
        diff_refs: diffs.diff_refs,
        fallback_diff_refs: diffs.fallback_diff_refs
      )
    end

    it "uses ActiveSupport::Gzip when reading from the cache" do
      expect(ActiveSupport::Gzip).to receive(:decompress).at_least(:once).and_call_original

      cache.write_if_empty
      cache.decorate(diff_file)
    end

    it "uses ActiveSupport::Gzip to compress data when writing to cache" do
      # at least once as Gitlab::Redis::Cache is a multistore
      expect(ActiveSupport::Gzip).to receive(:compress).at_least(1).and_call_original

      cache.send(:write_to_redis_hash, diff_hash)
    end
  end

  describe 'metrics' do
    let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current).and_return(transaction)
    end

    it 'observes :gitlab_redis_diff_caching_memory_usage_bytes' do
      expect(transaction)
        .to receive(:observe).with(:gitlab_redis_diff_caching_memory_usage_bytes, a_kind_of(Numeric))

      cache.write_if_empty
    end

    it 'records hit ratio metrics' do
      expect(transaction)
        .to receive(:increment).with(:gitlab_redis_diff_caching_requests_total).exactly(5).times
      expect(transaction)
        .to receive(:increment).with(:gitlab_redis_diff_caching_hits_total).exactly(4).times

      5.times do
        cache = described_class.new(merge_request.diffs)
        cache.write_if_empty
      end
    end
  end

  describe '#key' do
    subject { cache.key }

    def options_hash(options_array)
      OpenSSL::Digest::SHA256.hexdigest(options_array.join)
    end

    it 'returns cache key' do
      is_expected.to eq("highlighted-diff-files:#{cache.diffable.cache_key}:2:#{options_hash([cache.diff_options, true])}")
    end

    context 'when the `diff_line_syntax_highlighting` feature flag is disabled' do
      before do
        stub_feature_flags(diff_line_syntax_highlighting: false)
      end

      it 'returns the original version of the cache' do
        is_expected.to eq("highlighted-diff-files:#{cache.diffable.cache_key}:2:#{options_hash([cache.diff_options, false])}")
      end
    end
  end
end
