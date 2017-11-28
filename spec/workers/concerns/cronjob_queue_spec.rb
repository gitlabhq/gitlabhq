require 'spec_helper'

describe CronjobQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include CronjobQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('cronjob:dummy')
  end

  it 'disables retrying of failed jobs' do
    expect(worker.sidekiq_options['retry']).to eq(false)
  end
end
