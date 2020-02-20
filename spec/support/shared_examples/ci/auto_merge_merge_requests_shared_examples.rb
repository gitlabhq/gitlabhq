# frozen_string_literal: true

RSpec.shared_examples 'aborted merge requests for MWPS' do
  let(:aborted_message) do
    /aborted the automatic merge because target branch was updated/
  end

  it 'aborts auto_merge' do
    expect(merge_request.auto_merge_enabled?).to be_falsey
    expect(merge_request.notes.last.note).to match(aborted_message)
  end

  it 'removes merge_user' do
    expect(merge_request.merge_user).to be_nil
  end

  it 'does not add todos for merge user' do
    expect(user.todos.for_target(merge_request)).to be_empty
  end

  it 'adds todos for merge author' do
    expect(author.todos.for_target(merge_request)).to be_present.and be_all(&:pending?)
  end
end

RSpec.shared_examples 'maintained merge requests for MWPS' do
  it 'does not cancel auto merge' do
    expect(merge_request.auto_merge_enabled?).to be_truthy
    expect(merge_request.notes).to be_empty
  end

  it 'does not change merge_user' do
    expect(merge_request.merge_user).to eq(user)
  end

  it 'does not add todos' do
    expect(author.todos.for_target(merge_request)).to be_empty
    expect(user.todos.for_target(merge_request)).to be_empty
  end
end
