# frozen_string_literal: true

require 'spec_helper'

describe Mail::SMTPPool do
  describe '.create_pool' do
    it 'sets the default pool settings' do
      expect(ConnectionPool).to receive(:new).with(size: 5, timeout: 5).once

      described_class.create_pool
    end

    it 'allows overriding pool size and timeout' do
      expect(ConnectionPool).to receive(:new).with(size: 3, timeout: 2).once

      described_class.create_pool(pool_size: 3, pool_timeout: 2)
    end

    it 'creates an SMTP connection with the correct settings' do
      settings = { address: 'smtp.example.com', port: '465' }

      smtp_pool = described_class.create_pool(settings)

      expect(Mail::SMTPPool::Connection).to receive(:new).with(settings).once.and_call_original

      smtp_pool.checkout
    end
  end

  describe '#initialize' do
    it 'raises an error if a pool is not specified' do
      expect { described_class.new({}) }.to raise_error(
        ArgumentError, 'pool is required. You can create one using Mail::SMTPPool.create_pool.'
      )
    end
  end

  describe '#deliver!' do
    let(:mail) do
      Mail.new do
        from    'mikel@test.lindsaar.net'
        to      'you@test.lindsaar.net'
        subject 'This is a test email'
        body    'Test body'
      end
    end

    after do
      MockSMTP.reset
    end

    it 'delivers mail using a connection from the pool' do
      connection_pool = double(ConnectionPool)
      connection = double(Mail::SMTPPool::Connection)

      expect(connection_pool).to receive(:with).and_yield(connection)
      expect(connection).to receive(:deliver!).with(mail)

      described_class.new(pool: connection_pool).deliver!(mail)
    end

    it 'delivers mail' do
      described_class.new(pool: described_class.create_pool).deliver!(mail)

      expect(MockSMTP.deliveries.size).to eq(1)
    end

    context 'when called from Mail:Message' do
      before do
        mail.delivery_method(described_class, { pool: described_class.create_pool })
      end

      describe '#deliver' do
        it 'delivers mail' do
          mail.deliver

          expect(MockSMTP.deliveries.size).to eq(1)
        end
      end

      describe '#deliver!' do
        it 'delivers mail' do
          mail.deliver!

          expect(MockSMTP.deliveries.size).to eq(1)
        end
      end
    end
  end
end
