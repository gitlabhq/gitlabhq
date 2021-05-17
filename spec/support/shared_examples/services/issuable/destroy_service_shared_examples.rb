# frozen_string_literal: true

shared_examples_for 'service deleting todos' do
  it 'destroys associated todos asynchronously' do
    expect(TodosDestroyer::DestroyedIssuableWorker)
      .to receive(:perform_async)
      .with(issuable.id, issuable.class.name)

    subject.execute(issuable)
  end
end

shared_examples_for 'service deleting label links' do
  it 'destroys associated label links asynchronously' do
    expect(Issuable::LabelLinksDestroyWorker)
      .to receive(:perform_async)
      .with(issuable.id, issuable.class.name)

    subject.execute(issuable)
  end
end
