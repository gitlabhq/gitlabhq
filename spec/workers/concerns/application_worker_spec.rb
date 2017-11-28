require 'spec_helper'

describe ApplicationWorker do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
    end
  end

  describe 'Sidekiq options' do
    it 'sets the queue name based on the class name' do
      expect(worker.sidekiq_options['queue']).to eq('foo_bar_dummy')
    end
  end

  describe '.queue' do
    it 'returns the queue name' do
      worker.sidekiq_options queue: :some_queue

      expect(worker.queue).to eq('some_queue')
    end
  end
end
