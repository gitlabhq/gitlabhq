require 'spec_helper'

describe Gitlab::GithubImport::Queue do
  it 'sets the Sidekiq options for the worker' do
    worker = Class.new do
      include Sidekiq::Worker
      include Gitlab::GithubImport::Queue
    end

    expect(worker.sidekiq_options['queue']).to eq('github_importer')
  end
end
