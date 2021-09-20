# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::MergeRequestsPreloader do
  describe '#execute' do
    let_it_be_with_refind(:merge_requests) { create_list(:merge_request, 3) }
    let_it_be(:upvotes) { merge_requests.each { |m| create(:award_emoji, :upvote, awardable: m) } }

    it 'does not make n+1 queries' do
      described_class.new(merge_requests).execute

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        # expectations make sure the queries execute
        merge_requests.each do |m|
          expect(m.target_project.project_feature).not_to be_nil
          expect(m.lazy_upvotes_count).to eq(1)
        end
      end

      # 1 query for BatchLoader to load all upvotes at once
      expect(control.count).to eq(1)
    end

    it 'runs extra queries without preloading' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        # expectations make sure the queries execute
        merge_requests.each do |m|
          expect(m.target_project.project_feature).not_to be_nil
          expect(m.lazy_upvotes_count).to eq(1)
        end
      end

      # 4 queries per merge request =
      # 1 to load merge request
      # 1 to load project
      # 1 to load project_feature
      # 1 to load upvotes count
      expect(control.count).to eq(4 * merge_requests.size)
    end
  end
end
