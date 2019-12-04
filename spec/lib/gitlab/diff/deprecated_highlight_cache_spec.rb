# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::DeprecatedHighlightCache do
  let(:merge_request) { create(:merge_request_with_diffs) }

  subject(:cache) { described_class.new(merge_request.diffs, backend: backend) }

  describe '#decorate' do
    let(:backend) { double('backend').as_null_object }

    # Manually creates a Diff::File object to avoid triggering the cache on
    # the FileCollection::MergeRequestDiff
    let(:diff_file) do
      diffs = merge_request.diffs
      raw_diff = diffs.diffable.raw_diffs(diffs.diff_options.merge(paths: ['CHANGELOG'])).first
      Gitlab::Diff::File.new(raw_diff,
                             repository: diffs.project.repository,
                             diff_refs: diffs.diff_refs,
                             fallback_diff_refs: diffs.fallback_diff_refs)
    end

    it 'does not calculate highlighting when reading from cache' do
      cache.write_if_empty
      cache.decorate(diff_file)

      expect_any_instance_of(Gitlab::Diff::Highlight).not_to receive(:highlight)

      diff_file.highlighted_diff_lines
    end

    it 'assigns highlighted diff lines to the DiffFile' do
      cache.write_if_empty
      cache.decorate(diff_file)

      expect(diff_file.highlighted_diff_lines.size).to be > 5
    end

    it 'submits a single reading from the cache' do
      cache.decorate(diff_file)
      cache.decorate(diff_file)

      expect(backend).to have_received(:read).with(cache.key).once
    end
  end

  describe '#write_if_empty' do
    let(:backend) { double('backend', read: {}).as_null_object }

    it 'submits a single writing to the cache' do
      cache.write_if_empty
      cache.write_if_empty

      expect(backend).to have_received(:write).with(cache.key,
                                                    hash_including('CHANGELOG-false-false-false'),
                                                    expires_in: 1.week).once
    end
  end

  describe '#clear' do
    let(:backend) { double('backend').as_null_object }

    it 'clears cache' do
      cache.clear

      expect(backend).to have_received(:delete).with(cache.key)
    end
  end
end
