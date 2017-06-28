require 'spec_helper'

describe DedicatedSidekiqQueue do
  let(:worker) do
    Class.new do
      def self.name
        'Foo::Bar::DummyWorker'
      end

      include Sidekiq::Worker
      include DedicatedSidekiqQueue
    end
  end

  describe 'queue names' do
    it 'sets the queue name based on the class name' do
      expect(worker.sidekiq_options['queue']).to eq('foo_bar_dummy')
    end
  end
end
