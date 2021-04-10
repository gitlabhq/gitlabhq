# frozen_string_literal: true

require 'spec_helper'

describe Mail::SMTPPool::Connection do
  let(:connection) { described_class.new({}) }
  let(:mail) do
    Mail.new do
      from    'mikel@test.lindsaar.net'
      to      'you@test.lindsaar.net'
      subject 'This is a test email'
      body    'Test body'
    end
  end

  after do
    MockSMTP.clear_deliveries
  end

  describe '#deliver!' do
    it 'delivers mail using the same SMTP connection' do
      mock_smtp = MockSMTP.new

      expect(Net::SMTP).to receive(:new).once.and_return(mock_smtp)
      expect(mock_smtp).to receive(:sendmail).twice.and_call_original
      expect(mock_smtp).to receive(:rset).once.and_call_original

      connection.deliver!(mail)
      connection.deliver!(mail)

      expect(MockSMTP.deliveries.size).to eq(2)
    end

    context 'when RSET fails' do
      let(:mock_smtp) { MockSMTP.new }
      let(:mock_smtp_2) { MockSMTP.new }

      before do
        expect(Net::SMTP).to receive(:new).twice.and_return(mock_smtp, mock_smtp_2)
      end

      context 'with an IOError' do
        before do
          expect(mock_smtp).to receive(:rset).once.and_raise(IOError)
        end

        it 'creates a new SMTP connection' do
          expect(mock_smtp).to receive(:sendmail).once.and_call_original
          expect(mock_smtp).to receive(:finish).once.and_call_original
          expect(mock_smtp_2).to receive(:sendmail).once.and_call_original

          connection.deliver!(mail)
          connection.deliver!(mail)

          expect(MockSMTP.deliveries.size).to eq(2)
        end
      end

      context 'with an SMTP error' do
        before do
          expect(mock_smtp).to receive(:rset).once.and_raise(Net::SMTPServerBusy)
        end

        it 'creates a new SMTP connection' do
          expect(mock_smtp).to receive(:sendmail).once.and_call_original
          expect(mock_smtp).to receive(:finish).once.and_call_original
          expect(mock_smtp_2).to receive(:sendmail).once.and_call_original

          connection.deliver!(mail)
          connection.deliver!(mail)

          expect(MockSMTP.deliveries.size).to eq(2)
        end

        context 'and closing the old connection fails' do
          before do
            expect(mock_smtp).to receive(:finish).once.and_raise(IOError)
          end

          it 'creates a new SMTP connection' do
            expect(mock_smtp).to receive(:sendmail).once.and_call_original
            expect(mock_smtp_2).to receive(:sendmail).once.and_call_original

            connection.deliver!(mail)
            connection.deliver!(mail)

            expect(MockSMTP.deliveries.size).to eq(2)
          end
        end
      end
    end
  end
end
