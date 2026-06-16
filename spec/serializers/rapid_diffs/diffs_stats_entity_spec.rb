# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffsStatsEntity, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request_with_diffs) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needed to create diffs
  let(:diffs_resource) { merge_request.diffs }
  let(:options) do
    {
      email_path: 'email_format_path',
      diff_path: 'complete_diff_path'
    }
  end

  let(:entity) { described_class.new(diffs_resource, options) }

  context 'as json' do
    subject(:diffs_stats) { entity.as_json }

    it 'contains needed attributes' do
      expect(diffs_stats).to include(
        {
          diffs_stats: {
            added_lines: 119,
            removed_lines: 9,
            diffs_count: 20,
            real_size: '20'
          }
        })
    end

    context 'when the diff collection overflows hard limits' do
      before do
        allow(diffs_resource).to receive(:real_size).and_return('20+')
      end

      it 'exposes real_size with a "+" suffix' do
        expect(diffs_stats[:diffs_stats]).to include(real_size: '20+')
      end
    end

    where(:safe_lines, :safe_files, :safe_bytes, :safe_limits, :expected_overflow) do
      [
        [false, false, false, false, false],
        [true, false, false, false, true],
        [false, true, false, false, true],
        [false, false, true, false, true],
        [false, false, false, true, true],
        [true, true, true, true, true]
      ]
    end

    with_them do
      let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }

      before do
        allow(diffs_resource).to receive(:diff_files).and_return(diff_files)

        allow(diff_files).to receive_messages(
          collapsed_safe_lines?: safe_lines,
          collapsed_safe_files?: safe_files,
          collapsed_safe_bytes?: safe_bytes,
          collapsed_safe_limits?: safe_limits
        )
      end

      it 'returns correct overflow value' do
        if expected_overflow
          expect(diffs_stats).to include(
            overflow: {
              visible_count: 20,
              email_path: 'email_format_path',
              diff_path: 'complete_diff_path'
            }
          )
        else
          expect(diffs_stats).not_to have_key(:overflow)
        end
      end
    end
  end
end
