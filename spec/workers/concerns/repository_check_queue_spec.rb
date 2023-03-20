# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryCheckQueue, feature_category: :source_code_management do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include RepositoryCheckQueue
    end
  end

  it 'disables retrying of failed jobs' do
    expect(worker.sidekiq_options['retry']).to eq(false)
  end
end
