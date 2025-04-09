# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffsStatsEntity, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request_with_diffs) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needed to create diffs
  let(:diffs_resource) { merge_request.latest_diffs }
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
            added_lines: 118,
            removed_lines: 9,
            diffs_count: 20
          }
        })
    end

    context 'when diffs overflow' do
      let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }

      before do
        allow(diffs_resource).to receive(:diff_files).and_return(diff_files)
        allow(diff_files).to receive_messages(collapsed_safe_lines?: true, collapsed_safe_files?: false,
          collapsed_safe_bytes?: false)
      end

      it 'includes overflow information' do
        expect(diffs_stats).to include(
          {
            overflow: {
              visible_count: 20,
              email_path: 'email_format_path',
              diff_path: 'complete_diff_path'
            }
          })
      end
    end
  end
end
