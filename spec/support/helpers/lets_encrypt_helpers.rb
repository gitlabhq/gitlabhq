# frozen_string_literal: true

module LetsEncryptHelpers
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
end
