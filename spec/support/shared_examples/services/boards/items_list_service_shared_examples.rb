# frozen_string_literal: true

RSpec.shared_examples 'items list service' do
  it 'avoids N+1' do
    params = { board_id: board.id }
    control = ActiveRecord::QueryRecorder.new { described_class.new(parent, user, params).execute }

    new_list

    expect { described_class.new(parent, user, params).execute }.not_to exceed_query_limit(control)
  end

  it 'returns opened items when list_id is missing' do
    params = { board_id: board.id }

    items = described_class.new(parent, user, params).execute

    expect(items).to match_array(backlog_items)
  end

  it 'returns opened items when listing items from Backlog' do
    params = { board_id: board.id, id: backlog.id }

    items = described_class.new(parent, user, params).execute

    expect(items).to match_array(backlog_items)
  end

  it 'returns opened items that have label list applied when listing items from a label list' do
    params = { board_id: board.id, id: list1.id }

    items = described_class.new(parent, user, params).execute

    expect(items).to match_array(list1_items)
  end

  it 'returns closed items when listing items from Closed sorted by closed_at in descending order' do
    params = { board_id: board.id, id: closed.id }

    items = described_class.new(parent, user, params).execute

    expect(items).to eq(closed_items)
  end

  it 'raises an error if the list does not belong to the board' do
    list = create(list_factory) # rubocop:disable Rails/SaveBang
    service = described_class.new(parent, user, board_id: board.id, id: list.id)

    expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises an error if list id is invalid' do
    service = described_class.new(parent, user, board_id: board.id, id: nil)

    expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'returns items from all lists if :all_list is used' do
    params = { board_id: board.id, all_lists: true }

    items = described_class.new(parent, user, params).execute

    expect(items).to match_array(all_items)
  end
end
