shared_examples 'issues list service' do
  it 'delegates search to IssuesFinder' do
    params = { board_id: board.id, id: list1.id }

    expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

    described_class.new(parent, user, params).execute
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

    it 'returns closed issues when listing issues from Closed' do
      params = { board_id: board.id, id: closed.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [closed_issue4, closed_issue2, closed_issue5, closed_issue3, closed_issue1]
    end

    it 'returns opened issues that have label list applied when listing issues from a label list' do
      params = { board_id: board.id, id: list1.id }

      issues = described_class.new(parent, user, params).execute

      expect(issues).to eq [list1_issue3, list1_issue1, list1_issue2]
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
end
