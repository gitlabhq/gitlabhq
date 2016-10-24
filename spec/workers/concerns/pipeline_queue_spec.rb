require 'spec_helper'

describe PipelineQueue do
  let(:worker) do
    Class.new do
      include Sidekiq::Worker
      include PipelineQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('pipeline')
  end
end
