# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sidekiq::Worker' do
  let(:worker_class) do
    Class.new do
      include Sidekiq::Worker

      def perform
      end
    end
  end

  it 'allows sidekiq worker outside of a transaction' do
    expect { worker_class.perform_async }.not_to raise_error
  end

  it 'forbids queue sidekiq worker in a transaction' do
    Project.transaction do
      expect { worker_class.perform_async }.to raise_error(Sidekiq::Worker::EnqueueFromTransactionError)
    end
  end

  it 'allows sidekiq worker in a transaction if skipped' do
    Sidekiq::Worker.skipping_transaction_check do
      Project.transaction do
        expect { worker_class.perform_async }.not_to raise_error
      end
    end
  end

  it 'forbids queue sidekiq worker in a Ci::ApplicationRecord transaction' do
    Ci::Pipeline.transaction do
      expect { worker_class.perform_async }.to raise_error(Sidekiq::Worker::EnqueueFromTransactionError)
    end
  end
end
