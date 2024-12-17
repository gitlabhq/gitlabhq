# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pages::Domains::CreateAcmeOrderService, feature_category: :pages do
  include LetsEncryptHelpers

  let(:pages_domain) { create(:pages_domain) }

  let(:challenge) { ::Gitlab::LetsEncrypt::Challenge.new(acme_challenge_double) }

  let(:order_double) do
    Gitlab::LetsEncrypt::Order.new(acme_order_double).tap do |order|
      allow(order).to receive(:new_challenge).and_return(challenge)
    end
  end

  let(:lets_encrypt_client) do
    instance_double(Gitlab::LetsEncrypt::Client).tap do |client|
      allow(client).to receive(:new_order).with(pages_domain.domain)
        .and_return(order_double)
    end
  end

  let(:service) { described_class.new(pages_domain) }

  before do
    allow(::Gitlab::LetsEncrypt::Client).to receive(:new).and_return(lets_encrypt_client)
  end

  it_behaves_like 'returning a success service response', message: nil do
    subject { service.execute }

    it { expect(service.execute).to have_attributes(payload: { acme_order: PagesDomainAcmeOrder.last }) }

    it { expect { service.execute }.to change { PagesDomainAcmeOrder.count }.by(1) }
  end

  it 'saves order to database before requesting validation' do
    allow(pages_domain.acme_orders).to receive(:create!).and_call_original
    allow(challenge).to receive(:request_validation).and_call_original

    service.execute

    expect(pages_domain.acme_orders).to have_received(:create!).ordered
    expect(challenge).to have_received(:request_validation).ordered
  end

  it 'generates and saves private key' do
    service_response = service.execute

    saved_order = service_response[:acme_order]
    expect { OpenSSL::PKey::RSA.new(saved_order.private_key) }.not_to raise_error
  end

  it 'properly saves order attributes' do
    service_response = service.execute

    expect(service_response[:acme_order]).to have_attributes(
      url: order_double.url,
      expires_at: be_like_time(order_double.expires)
    )
  end

  it 'properly saves challenge attributes' do
    service_response = service.execute

    expect(service_response[:acme_order]).to have_attributes(
      challenge_token: challenge.token,
      challenge_file_content: challenge.file_content
    )
  end

  describe 'when acme order is not created due to client error' do
    using RSpec::Parameterized::TableSyntax

    let(:lets_encrypt_client) do
      instance_double(Gitlab::LetsEncrypt::Client).tap do |client|
        allow(client).to receive(:new_order).with(pages_domain.domain)
          .and_raise(lets_encrypt_client_error, lets_encrypt_client_error_message)
      end
    end

    where(:lets_encrypt_client_error, :lets_encrypt_client_error_message) do
      Acme::Client::Error::RejectedIdentifier | 'Invalid identifiers requested :: Cannot issue for "local": Domain name needs at least one dot' # rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective -- Ensuring one line table syntax
      Acme::Client::Error::BadCSR             | 'Error finalizing order :: signature algorithm not supported'
      Acme::Client::Error                     | 'Other acme client error'
      Acme::Client::Error                     | nil
    end

    with_them do
      it_behaves_like 'returning an error service response', message: params[:lets_encrypt_client_error_message] do
        subject { service.execute }

        it { expect(service.execute).to have_attributes(payload: { acme_order: nil }) }
      end
    end
  end
end
