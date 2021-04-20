# frozen_string_literal: true

shared_examples_for 'service deleting todos' do
  before do
    stub_feature_flags(destroy_issuable_todos_async: group)
  end

  it 'destroys associated todos asynchronously' do
    expect(TodosDestroyer::DestroyedIssuableWorker)
      .to receive(:perform_async)
      .with(issuable.id, issuable.class.name)

    subject.execute(issuable)
  end

  context 'when destroy_issuable_todos_async feature is disabled for group' do
    before do
      stub_feature_flags(destroy_issuable_todos_async: false)
    end

    it 'destroy associated todos synchronously' do
      expect_next_instance_of(TodosDestroyer::DestroyedIssuableWorker) do |worker|
        expect(worker)
          .to receive(:perform)
          .with(issuable.id, issuable.class.name)
      end

      subject.execute(issuable)
    end
  end
end
