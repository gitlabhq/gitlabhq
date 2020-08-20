# frozen_string_literal: true

RSpec.shared_examples 'issues list service' do
  it 'delegates search to IssuesFinder' do
    params = { board_id: board.id, id: list1.id }

    expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

    described_class.new(parent, user, params).execute
  end

  describe '#metadata' do
    it 'returns issues count for list' do
      params = { board_id: board.id, id: list1.id }

      metadata = described_class.new(parent, user, params).metadata

      expect(metadata[:size]).to eq(3)
    end
  end

  it 'avoids N+1' do
    params = { board_id: board.id }
    control = ActiveRecord::QueryRecorder.new { described_class.new(parent, user, params).execute }

    create(:list, board: board)

    expect { described_class.new(parent, user, params).execute }.not_to exceed_query_limit(control)
  end

  context 'issues are ordered by priority' do
    it 'returns opened issues when list_id is missing' do
      params = { board_id: board.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
    end

    it 'returns opened issues when listing issues from Backlog' do
      params = { board_id: board.id, id: backlog.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
    end

    it 'returns opened issues that have label list applied when listing issues from a label list' do
      params = { board_id: board.id, id: list1.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [list1_issue3, list1_issue1, list1_issue2]
    end
  end

  context 'issues are ordered by date of closing' do
    it 'returns closed issues when listing issues from Closed' do
      params = { board_id: board.id, id: closed.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [closed_issue1, closed_issue2, closed_issue3, closed_issue4, closed_issue5]
    end
  end

  context 'with list that does not belong to the board' do
    it 'raises an error' do
      list = create(:list)
      service = described_class.new(parent, user, board_id: board.id, id: list.id)

      expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with invalid list id' do
    it 'raises an error' do
      service = described_class.new(parent, user, board_id: board.id, id: nil)

      expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when :all_lists is used' do
    it 'returns issues from all lists' do
      params = { board_id: board.id, all_lists: true }

      issues = described_class.new(parent, user, params).execute

      expected = [opened_issue2, reopened_issue1, opened_issue1, list1_issue1,
                  list1_issue2, list1_issue3, list2_issue1, closed_issue1,
                  closed_issue2, closed_issue3, closed_issue4, closed_issue5]
      expect(issues).to match_array(expected)
    end
  end
end
