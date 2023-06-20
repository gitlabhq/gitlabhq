# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::MergeRequestDiffPreloader do
  let_it_be(:merge_request_1) { create(:merge_request) }
  let_it_be(:merge_request_2) { create(:merge_request) }
  let_it_be(:merge_request_3) { create(:merge_request, :skip_diff_creation) }

  let(:merge_requests) { [merge_request_1, merge_request_2, merge_request_3] }

  def trigger(merge_requests)
    Array(merge_requests).each(&:merge_request_diff)
  end

  def merge_requests_with_preloaded_diff
    described_class.new(MergeRequest.where(id: merge_requests.map(&:id)).to_a).preload_all
  end

  it 'does not trigger N+1 queries' do
    # warmup
    trigger(merge_requests_with_preloaded_diff)

    first_merge_request = merge_requests_with_preloaded_diff.first
    clean_merge_requests = merge_requests_with_preloaded_diff

    expect { trigger(clean_merge_requests) }.to issue_same_number_of_queries_as { trigger(first_merge_request) }
  end
end
