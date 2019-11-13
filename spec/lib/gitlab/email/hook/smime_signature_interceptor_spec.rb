# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Hook::SmimeSignatureInterceptor do
  include SmimeHelper

  # cert generation is an expensive operation and they are used read-only,
  # so we share them as instance variables in all tests
  before :context do
    @root_ca = generate_root
    @cert = generate_cert(root_ca: @root_ca)
  end

  let(:root_certificate) do
    Gitlab::Email::Smime::Certificate.new(@root_ca[:key], @root_ca[:cert])
  end

  let(:certificate) do
    Gitlab::Email::Smime::Certificate.new(@cert[:key], @cert[:cert])
  end

  let(:mail) do
    ActionMailer::Base.mail(to: 'test@example.com', from: 'info@example.com', body: 'signed hello')
  end

  before do
    allow(Gitlab::Email::Smime::Certificate).to receive_messages(from_files: certificate)

    Mail.register_interceptor(described_class)
    mail.deliver_now
  end

  after do
    Mail.unregister_interceptor(described_class)
  end

  it 'signs the email appropriately with SMIME' do
    expect(mail.header['To'].value).to eq('test@example.com')
    expect(mail.header['From'].value).to eq('info@example.com')
    expect(mail.header['Content-Type'].value).to match('multipart/signed').and match('protocol="application/x-pkcs7-signature"')

    # verify signature and obtain pkcs7 encoded content
    p7enc = Gitlab::Email::Smime::Signer.verify_signature(
      cert: certificate.cert,
      ca_cert: root_certificate.cert,
      signed_data: mail.encoded)

    # envelope in a Mail object and obtain the body
    decoded_mail = Mail.new(p7enc.data)

    expect(decoded_mail.body.encoded).to eq('signed hello')
  end
end
