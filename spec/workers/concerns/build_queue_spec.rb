require 'spec_helper'

describe BuildQueue do
  let(:worker) do
    Class.new do
      include Sidekiq::Worker
      include BuildQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('build')
  end
end
