# frozen_string_literal: true

module LetsEncryptHelpers
  ACME_ORDER_METHODS = {
    url: 'https://example.com/',
    status: 'valid',
    expires: 2.days.from_now
  }.freeze

  ACME_CHALLENGE_METHODS = {
    status: 'pending',
    token: 'tokenvalue',
    file_content: 'hereisfilecontent',
    request_validation: true,
    error: nil
  }.freeze

  def stub_lets_encrypt_settings
    stub_application_setting(
      lets_encrypt_notification_email: 'myemail@test.example.com',
      lets_encrypt_terms_of_service_accepted: true
    )
  end

  def stub_lets_encrypt_client
    client = instance_double('Acme::Client')

    allow(client).to receive(:new_account)
    allow(client).to receive(:terms_of_service).and_return(
      "https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf"
    )

    allow(Acme::Client).to receive(:new).with(
      private_key: kind_of(OpenSSL::PKey::RSA),
      directory: ::Gitlab::LetsEncrypt::Client::STAGING_DIRECTORY_URL
    ).and_return(client)

    client
  end

  def acme_challenge_double(attributes = {})
    challenge = instance_double('Acme::Client::Resources::Challenges::HTTP01')
    allow(challenge).to receive_messages(ACME_CHALLENGE_METHODS.merge(attributes))
    challenge
  end

  def acme_authorization_double(challenge = acme_challenge_double)
    authorization = instance_double('Acme::Client::Resources::Authorization')
    allow(authorization).to receive(:http).and_return(challenge)
    allow(authorization).to receive(:challenges).and_return([challenge])
    authorization
  end

  def acme_order_double(attributes = {})
    acme_order = instance_double('Acme::Client::Resources::Order')
    allow(acme_order).to receive_messages(ACME_ORDER_METHODS.merge(attributes))
    allow(acme_order).to receive(:authorizations).and_return([acme_authorization_double]) unless attributes[:authorizations]
    allow(acme_order).to receive(:finalize)
    acme_order
  end
end
