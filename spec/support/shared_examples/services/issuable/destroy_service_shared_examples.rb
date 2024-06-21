# frozen_string_literal: true

RSpec.shared_examples_for 'service scheduling async deletes' do
  it 'destroys associated todos asynchronously', :sidekiq_inline do
    expect(worker_class).to receive(:perform_async).with(issuable.id, issuable.class.base_class.name)

    if try(:sync_object).present?
      expect(worker_class).to receive(:perform_async).with(sync_object.id, sync_object.class.base_class.name)
    end

    subject.execute(issuable)
  end

  it 'works inside a transaction', :sidekiq_inline do
    expect(worker_class).to receive(:perform_async).with(issuable.id, issuable.class.base_class.name)

    if try(:sync_object).present?
      expect(worker_class).to receive(:perform_async).with(sync_object.id, sync_object.class.base_class.name)
    end

    ApplicationRecord.transaction do
      subject.execute(issuable)
    end
  end
end

RSpec.shared_examples_for 'service deleting todos' do
  it_behaves_like 'service scheduling async deletes' do
    let(:worker_class) { TodosDestroyer::DestroyedIssuableWorker }
  end
end

RSpec.shared_examples_for 'service deleting label links' do
  it_behaves_like 'service scheduling async deletes' do
    let(:worker_class) { Issuable::LabelLinksDestroyWorker }
  end
end
