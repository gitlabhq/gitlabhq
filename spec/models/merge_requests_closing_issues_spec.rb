# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsClosingIssues, feature_category: :code_review_workflow do
  let_it_be(:namespace) { create_default(:namespace).freeze }
  let_it_be(:project) { create_default(:project).freeze }
  let_it_be(:merge_request) { create_default(:merge_request, source_project: project).freeze }
  let_it_be(:issue1) { create(:issue, project: project) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:closes_issue1) { create(:merge_requests_closing_issues, issue: issue1, merge_request: merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'enums' do
    it 'defines link_type' do
      expect(described_class.link_types).to eq('closes' => 0, 'mentioned' => 1, 'related' => 2)
    end

    it 'defaults link_type to closes for new records' do
      expect(described_class.new.link_type).to eq('closes')
    end
  end

  describe 'validations' do
    it 'requires merge_request_id to be unique per (issue_id, link_type)', :aggregate_failures do
      duplicate = build(:merge_requests_closing_issues,
        issue: issue1, merge_request: merge_request, link_type: closes_issue1.link_type)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:merge_request_id]).to be_present
    end

    it 'allows a mentioned row alongside an existing closes row for the same (mr, issue)' do
      mentioned = build(:merge_requests_closing_issues,
        issue: issue1, merge_request: merge_request,
        link_type: :mentioned, from_mr_description: false)

      expect(mentioned).to be_valid
    end

    describe 'ensure_related_links_are_not_from_description' do
      using RSpec::Parameterized::TableSyntax

      where(:link_type, :from_mr_description, :expected_valid) do
        :related   | true  | false
        :mentioned | true  | true
        :closes    | true  | true
        :related   | false | true
        :mentioned | false | true
        :closes    | false | true
      end

      with_them do
        let(:record) do
          build(:merge_requests_closing_issues,
            issue: issue2, merge_request: merge_request,
            link_type: link_type, from_mr_description: from_mr_description)
        end

        it 'only allows from_mr_description for description-derived link types', :aggregate_failures do
          expect(record.valid?).to eq(expected_valid)
          expect(record.errors[:from_mr_description]).to be_present unless expected_valid
        end
      end
    end
  end

  describe 'partial unique index' do
    # These bypass the model validation to assert the DB-level partial unique
    # index (on (merge_request_id, issue_id, link_type) WHERE link_type <> 0)
    # added for every link type except closes (which has legacy duplicates).
    def insert_duplicate(link_type)
      create(:merge_requests_closing_issues,
        issue: issue2, merge_request: merge_request, link_type: link_type, from_mr_description: false)

      build(:merge_requests_closing_issues,
        issue: issue2, merge_request: merge_request, link_type: link_type, from_mr_description: false)
        .save!(validate: false)
    end

    it 'rejects duplicate (merge_request_id, issue_id) rows for mentioned' do
      expect { insert_duplicate(:mentioned) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'rejects duplicate (merge_request_id, issue_id) rows for related' do
      expect { insert_duplicate(:related) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows duplicate (merge_request_id, issue_id) rows for closes' do
      expect { insert_duplicate(:closes) }.not_to raise_error
    end

    it 'allows a mentioned and a related row for the same (merge_request_id, issue_id)' do
      create(:merge_requests_closing_issues,
        issue: issue2, merge_request: merge_request, link_type: :mentioned, from_mr_description: false)

      related = build(:merge_requests_closing_issues,
        issue: issue2, merge_request: merge_request, link_type: :related, from_mr_description: false)

      expect { related.save!(validate: false) }.not_to raise_error
    end
  end

  describe 'scopes' do
    describe '.with_opened_merge_request' do
      let(:closed_merge_request) do
        create(:merge_request, :closed, source_project: project, target_branch: 'f2')
      end

      subject { described_class.with_opened_merge_request }

      before do
        create(:merge_requests_closing_issues, issue: issue2, merge_request: closed_merge_request)
      end

      it { is_expected.to contain_exactly(closes_issue1) }
    end

    describe '.from_mr_description' do
      before do
        create(:merge_requests_closing_issues, issue: issue2, merge_request: merge_request, from_mr_description: false)
      end

      subject { described_class.from_mr_description }

      it { is_expected.to contain_exactly(closes_issue1) }
    end

    describe '.link_type_closes (enum-generated)' do
      let_it_be(:mentioned_row) do
        create(:merge_requests_closing_issues,
          issue: issue2, merge_request: merge_request,
          link_type: :mentioned, from_mr_description: false)
      end

      it 'returns only closes rows' do
        expect(described_class.link_type_closes).to contain_exactly(closes_issue1)
      end
    end

    describe '.by_link_types' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:mentioned_row) do
        create(:merge_requests_closing_issues,
          issue: issue2, merge_request: merge_request,
          link_type: :mentioned, from_mr_description: false)
      end

      let_it_be(:related_row) do
        create(:merge_requests_closing_issues,
          issue: issue1, merge_request: merge_request,
          link_type: :related, from_mr_description: false)
      end

      where(:types, :expected) do
        [:closes]                       | lazy { [closes_issue1] }
        [:mentioned]                    | lazy { [mentioned_row] }
        [:related]                      | lazy { [related_row] }
        [:closes, :related]             | lazy { [closes_issue1, related_row] }
        [:closes, :mentioned, :related] | lazy { [closes_issue1, mentioned_row, related_row] }
      end

      with_them do
        it 'returns only the rows with the given link types' do
          expect(described_class.by_link_types(types)).to match_array(expected)
        end
      end
    end
  end

  describe '.count_for_issue / .count_for_collection (audit coverage)' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:mentioned_row) do
      create(:merge_requests_closing_issues,
        issue: issue1, merge_request: merge_request,
        link_type: :mentioned, from_mr_description: false)
    end

    it 'counts only closes rows for a single issue' do
      expect(described_class.count_for_issue(issue1.id, admin)).to eq(1)
    end

    it 'counts only closes rows for a collection' do
      counts = described_class.count_for_collection([issue1.id], admin).to_h
      expect(counts[issue1.id]).to eq(1)
    end
  end

  describe '.auto_close_issue_ids' do
    let_it_be(:closed_mr) do
      create(:merge_request, :closed, source_project: project, target_branch: 'auto-close-closed')
    end

    let_it_be(:issue_with_closed_mr) { create(:issue, project: project) }
    let_it_be(:issue_with_mentioned_mr) { create(:issue, project: project) }

    let_it_be(:closes_closed_mr) do
      create(:merge_requests_closing_issues, issue: issue_with_closed_mr, merge_request: closed_mr)
    end

    let_it_be(:mentioned_only_row) do
      create(:merge_requests_closing_issues,
        issue: issue_with_mentioned_mr, merge_request: merge_request,
        link_type: :mentioned, from_mr_description: false)
    end

    subject(:auto_close_ids) { described_class.auto_close_issue_ids(issue_ids) }

    context 'with an opened closes-type merge request' do
      let(:issue_ids) { [issue1.id, issue_with_closed_mr.id, issue_with_mentioned_mr.id] }

      it 'returns a Set with only the relevant issue ids', :aggregate_failures do
        is_expected.to be_a(Set)
        is_expected.to contain_exactly(issue1.id)
      end
    end

    context 'without an opened closes-type merge request' do
      let(:issue_ids) { [issue_with_closed_mr.id, issue_with_mentioned_mr.id] }

      it 'returns an empty Set', :aggregate_failures do
        is_expected.to be_a(Set)
        is_expected.to be_empty
      end
    end
  end
end
