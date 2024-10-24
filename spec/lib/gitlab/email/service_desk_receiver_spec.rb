# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDeskReceiver, feature_category: :service_desk do
  let(:email) { fixture_file('emails/service_desk_custom_address.eml') }
  let(:receiver) { described_class.new(email) }

  context 'when the email contains a valid email address' do
    shared_examples 'received successfully' do
      it 'finds the service desk key' do
        expect { receiver.execute }.not_to raise_error
      end
    end

    before do
      stub_service_desk_email_setting(enabled: true, address: 'support+%{key}@example.com')

      handler = double(execute: true, metrics_event: true, metrics_params: true)
      expected_params = [
        an_instance_of(Mail::Message), nil,
        { service_desk_key: 'project_slug-project_key' }
      ]

      expect(Gitlab::Email::Handler::ServiceDeskHandler)
        .to receive(:new).with(*expected_params).and_return(handler)
    end

    context 'when in a To header' do
      it_behaves_like 'received successfully'
    end

    context 'when the email contains a valid email address in a header' do
      let(:service_desk_email) { "support+project_slug-project_key@example.com" }

      context 'when in a Delivered-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_reply.eml') }

        it_behaves_like 'received successfully'
      end

      context 'when in a Envelope-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_envelope_to.eml') }

        it_behaves_like 'received successfully'
      end

      context 'when in a X-Envelope-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_x_envelope_to.eml') }

        it_behaves_like 'received successfully'
      end

      context 'when in a X-Original-To header' do
        let(:email) do
          <<~EMAIL
          From: from@example.com
          To: to@example.com
          X-Original-To: #{service_desk_email}
          Subject: Issue titile

          Issue description
          EMAIL
        end

        it_behaves_like 'received successfully'
      end

      context 'when in a X-Forwarded-To header' do
        let(:email) do
          <<~EMAIL
          From: from@example.com
          To: to@example.com
          X-Forwarded-To: #{service_desk_email}
          Subject: Issue titile

          Issue description
          EMAIL
        end

        it_behaves_like 'received successfully'
      end

      context 'when in a X-Delivered-To header' do
        let(:email) do
          <<~EMAIL
          From: from@example.com
          To: to@example.com
          X-Delivered-To: #{service_desk_email}
          Subject: Issue titile

          Issue description
          EMAIL
        end

        it_behaves_like 'received successfully'
      end

      context 'when in a Cc header' do
        let(:email) do
          <<~EMAIL
          From: from@example.com
          To: to@example.com
          Cc: #{service_desk_email}
          Subject: Issue titile

          Issue description
          EMAIL
        end

        it_behaves_like 'received successfully'
      end
    end
  end

  context 'when the email contains no key in the To header and contains reference header with no key' do
    let(:email) { fixture_file('emails/service_desk_reference_headers.eml') }

    before do
      stub_service_desk_email_setting(enabled: true, address: 'support+%{key}@example.com')
    end

    it 'sends a rejection email' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context 'when the email does not contain a valid email address' do
    before do
      stub_service_desk_email_setting(enabled: true, address: 'other_support+%{key}@example.com')
    end

    it 'raises an error' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end
end
