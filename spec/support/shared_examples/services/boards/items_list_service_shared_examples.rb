# frozen_string_literal: true

RSpec.shared_examples 'items list service' do
  it 'avoids N+1' do
    params = { board_id: board.id }
    control = ActiveRecord::QueryRecorder.new { list_service(params).execute }

    new_list

    expect { list_service(params).execute }.not_to exceed_query_limit(control)
  end

  it 'returns opened items when list_id and list are missing' do
    params = { board_id: board.id }

    items = list_service(params).execute

    expect(items).to match_array(backlog_items)
  end

  it 'returns opened items when listing items from Backlog' do
    params = { board_id: board.id, id: backlog.id }

    items = list_service(params).execute

    expect(items).to match_array(backlog_items)
  end

  it 'returns opened items that have label list applied when listing items from a label list' do
    params = { board_id: board.id, id: list1.id }

    items = list_service(params).execute

    expect(items).to match_array(list1_items)
  end

  it 'returns closed items when listing items from Closed sorted by closed_at in descending order' do
    params = { board_id: board.id, id: closed.id }

    items = list_service(params).execute

    expect(items).to eq(closed_items)
  end

  it 'raises an error if the list does not belong to the board' do
    list = create(list_factory) # rubocop:disable Rails/SaveBang
    params = { board_id: board.id, id: list.id }

    service = list_service(params)

    expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises an error if list and list id are invalid or missing' do
    params = { board_id: board.id, id: nil, list: nil }

    service = list_service(params)

    expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'returns items from all lists if :all_list is used' do
    params = { board_id: board.id, all_lists: true }

    items = list_service(params).execute

    expect(items).to match_array(all_items)
  end

  it 'returns opened items that have label list applied when using list param' do
    params = { board_id: board.id, list: list1 }

    items = list_service(params).execute

    expect(items).to match_array(list1_items)
  end

  def list_service(params)
    args = [parent, user].push(params)

    described_class.new(*args)
  end
end
