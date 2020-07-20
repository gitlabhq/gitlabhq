# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Queue do
  it 'sets the Sidekiq options for the worker' do
    worker = Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include Gitlab::GithubImport::Queue
    end

    expect(worker.sidekiq_options['queue']).to eq('github_importer:dummy')
  end
end
