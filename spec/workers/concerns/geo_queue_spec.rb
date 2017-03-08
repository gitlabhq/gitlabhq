require 'spec_helper'

describe GeoQueue do
  let(:worker) do
    Class.new do
      include Sidekiq::Worker
      include GeoQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('geo')
  end
end
