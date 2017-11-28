require 'spec_helper'

describe GeoQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include GeoQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('geo:dummy')
  end
end
