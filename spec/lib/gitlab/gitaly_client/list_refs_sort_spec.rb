# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::ListRefsSort, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  subject(:sort) { described_class.new(sort_by) }

  where(:sort_by, :key, :direction) do
    nil | Gitaly::ListRefsRequest::SortBy::Key::REFNAME | Gitaly::SortDirection::ASCENDING
    'name_asc' | Gitaly::ListRefsRequest::SortBy::Key::REFNAME | Gitaly::SortDirection::ASCENDING
    'name_desc' | Gitaly::ListRefsRequest::SortBy::Key::REFNAME | Gitaly::SortDirection::DESCENDING
    'updated_asc' | Gitaly::ListRefsRequest::SortBy::Key::CREATORDATE | Gitaly::SortDirection::ASCENDING
    'updated_desc' | Gitaly::ListRefsRequest::SortBy::Key::CREATORDATE | Gitaly::SortDirection::DESCENDING
    'UPDATED_DESC' | Gitaly::ListRefsRequest::SortBy::Key::CREATORDATE | Gitaly::SortDirection::DESCENDING
    'unknown' | Gitaly::ListRefsRequest::SortBy::Key::REFNAME | Gitaly::SortDirection::ASCENDING
  end

  with_them do
    it 'is correct' do
      expect(sort.gitaly_sort_by).to eq(Gitaly::ListRefsRequest::SortBy.new(key: key, direction: direction))
    end
  end
end
