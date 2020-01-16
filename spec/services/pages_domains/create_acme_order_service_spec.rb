# frozen_string_literal: true

require 'spec_helper'

describe PagesDomains::CreateAcmeOrderService do
  include LetsEncryptHelpers

  let(:pages_domain) { create(:pages_domain) }

  let(:challenge) { ::Gitlab::LetsEncrypt::Challenge.new(acme_challenge_double) }

  let(:order_double) do
    Gitlab::LetsEncrypt::Order.new(acme_order_double).tap do |order|
      allow(order).to receive(:new_challenge).and_return(challenge)
    end
  end

  let(:lets_encrypt_client) do
    instance_double('Gitlab::LetsEncrypt::Client').tap do |client|
      allow(client).to receive(:new_order).with(pages_domain.domain)
        .and_return(order_double)
    end
  end

  let(:service) { described_class.new(pages_domain) }

  before do
    allow(::Gitlab::LetsEncrypt::Client).to receive(:new).and_return(lets_encrypt_client)
  end

  it 'saves order to database before requesting validation' do
    allow(pages_domain.acme_orders).to receive(:create!).and_call_original
    allow(challenge).to receive(:request_validation).and_call_original

    service.execute

    expect(pages_domain.acme_orders).to have_received(:create!).ordered
    expect(challenge).to have_received(:request_validation).ordered
  end

  it 'generates and saves private key' do
    service.execute

    saved_order = PagesDomainAcmeOrder.last
    expect { OpenSSL::PKey::RSA.new(saved_order.private_key) }.not_to raise_error
  end

  it 'properly saves order url' do
    service.execute

    saved_order = PagesDomainAcmeOrder.last
    expect(saved_order.url).to eq(order_double.url)
  end

  context 'when order expires in 2 days' do
    it 'sets expiration time in 2 hours' do
      Timecop.freeze do
        service.execute

        saved_order = PagesDomainAcmeOrder.last
        expect(saved_order.expires_at).to be_like_time(2.hours.from_now)
      end
    end
  end

  context 'when order expires in an hour' do
    it 'sets expiration time accordingly to order' do
      Timecop.freeze do
        allow(order_double).to receive(:expires).and_return(1.hour.from_now)
        service.execute

        saved_order = PagesDomainAcmeOrder.last
        expect(saved_order.expires_at).to be_like_time(1.hour.from_now)
      end
    end
  end

  it 'properly saves challenge attributes' do
    service.execute

    saved_order = PagesDomainAcmeOrder.last
    expect(saved_order.challenge_token).to eq(challenge.token)
    expect(saved_order.challenge_file_content).to eq(challenge.file_content)
  end
end
