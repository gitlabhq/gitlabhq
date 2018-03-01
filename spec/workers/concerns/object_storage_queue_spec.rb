require 'spec_helper'

describe ObjectStorageQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include ObjectStorageQueue
    end
  end

  it 'sets a default object storage queue automatically' do
    expect(worker.sidekiq_options['queue'])
      .to eq 'object_storage:dummy'
  end
end
