# frozen_string_literal: true

RSpec.shared_examples 'a retryable job' do
  describe '#enqueue_immediately?' do
    it 'defaults to false' do
      expect(subject.enqueue_immediately?).to eq(false)
    end
  end

  describe '#set_enqueue_immediately!' do
    it 'changes #enqueue_immediately? to true' do
      expect { subject.set_enqueue_immediately! }
        .to change { subject.enqueue_immediately? }.from(false).to(true)
    end
  end
end
