# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sidekiq::Worker', feature_category: :shared do
  shared_examples_for 'a forbiddable operation within a transaction' do
    it 'allows the operation outside of a transaction' do
      expect { operation }.not_to raise_error
    end

    it 'forbids the operation within a transaction' do
      ApplicationRecord.transaction do
        expect { operation }.to raise_error(Sidekiq::Worker::EnqueueFromTransactionError)
      end
    end

    it 'allows the operation within a transaction if skipped' do
      Sidekiq::Worker.skipping_transaction_check do
        ApplicationRecord.transaction do
          expect { operation }.not_to raise_error
        end
      end
    end

    it 'allows the operation if lock thread is set' do
      Sidekiq::Worker.skipping_transaction_check do
        thread = Thread.new do
          Thread.current.abort_on_exception = true

          ApplicationRecord.transaction do
            expect { operation }.not_to raise_error
          end
        end

        thread.join
      end
    end

    it 'forbids the operation if it is within a Ci::ApplicationRecord transaction' do
      Ci::Pipeline.transaction do
        expect { operation }.to raise_error(Sidekiq::Worker::EnqueueFromTransactionError)
      end
    end
  end

  context 'for sidekiq workers' do
    let(:worker_class) do
      Class.new do
        include Sidekiq::Worker

        def perform; end
      end
    end

    let(:operation) { worker_class.perform_async }

    it_behaves_like 'a forbiddable operation within a transaction'
  end

  context 'for mailers' do
    let(:mailer_class) do
      Class.new(ApplicationMailer) do
        def self.name
          'Notify'
        end

        def test_mail; end
      end
    end

    let(:operation) { mailer_class.test_mail.deliver_later }

    it_behaves_like 'a forbiddable operation within a transaction'
  end
end
