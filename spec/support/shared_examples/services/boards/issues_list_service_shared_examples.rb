# frozen_string_literal: true

RSpec.shared_examples 'issues list service' do
  it 'delegates search to IssuesFinder' do
    params = { board_id: board.id, id: list1.id }

    expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

    described_class.new(parent, user, params).execute
  end

  it 'returns issues for anonymous users' do
    params = { board_id: board.id, id: list1.id }

    expect(described_class.new(parent, nil, params).execute).to be_kind_of(ActiveRecord::Relation)
  end

  context 'with work_items_beta feature flag disabled' do
    before do
      stub_feature_flags(work_items_beta: false)
    end

    it 'returns issues for anonymous users' do
      params = { board_id: board.id, id: list1.id }

      expect(described_class.new(parent, nil, params).execute).to be_kind_of(ActiveRecord::Relation)
    end
  end

  describe '#metadata' do
    it 'returns issues count for list' do
      params = { board_id: board.id, id: list1.id }

      metadata = described_class.new(parent, user, params).metadata

      expect(metadata[:size]).to eq(3)
    end
  end

  it_behaves_like 'items list service' do
    let(:backlog_items) { [opened_issue2, reopened_issue1, opened_issue1] }
    let(:list1_items) { [list1_issue3, list1_issue1, list1_issue2] }
    let(:closed_items) { [closed_issue1, closed_issue2, closed_issue3, closed_issue4, closed_issue5] }
    let(:all_items) { backlog_items + list1_items + closed_items + [list2_issue1] }
    let(:list_factory) { :list }
    let(:new_list) { create(:list, board: board) }
  end
end
