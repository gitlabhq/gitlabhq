require 'spec_helper'

describe RepositoryCheckQueue do
  let(:worker) do
    Class.new do
      include Sidekiq::Worker
      include RepositoryCheckQueue
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('repository_check')
  end

  it 'disables retrying of failed jobs' do
    expect(worker.sidekiq_options['retry']).to eq(false)
  end
end
