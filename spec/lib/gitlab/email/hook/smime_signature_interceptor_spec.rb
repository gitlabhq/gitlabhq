# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::SmimeSignatureInterceptor do
  include SmimeHelper

  # certs generation is an expensive operation and they are used read-only,
  # so we share them as instance variables in all tests
  before :context do
    @root_ca = generate_root
    @intermediate_ca = generate_intermediate(signer_ca: @root_ca)
    @cert = generate_cert(signer_ca: @intermediate_ca)
  end

  let(:root_certificate) do
    Gitlab::X509::Certificate.new(@root_ca[:key], @root_ca[:cert])
  end

  let(:intermediate_certificate) do
    Gitlab::X509::Certificate.new(@intermediate_ca[:key], @intermediate_ca[:cert])
  end

  let(:certificate) do
    Gitlab::X509::Certificate.new(@cert[:key], @cert[:cert], [intermediate_certificate.cert])
  end

  let(:mail_body) { "signed hello with Unicode €áø and\r\n newlines\r\n" }

  let(:mail) do
    ActionMailer::Base.mail(to: 'test@example.com',
      from: 'info@example.com',
      content_transfer_encoding: 'quoted-printable',
      content_type: 'text/plain; charset=UTF-8',
      body: mail_body)
  end

  before do
    allow(described_class).to receive(:certificate).and_return(certificate)

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
    expect(mail.header.include?('Content-Disposition')).to eq(false)

    # verify signature and obtain pkcs7 encoded content
    p7enc = Gitlab::Email::Smime::Signer.verify_signature(
      ca_certs: root_certificate.cert,
      signed_data: mail.encoded)

    expect(p7enc).not_to be_nil

    # re-verify signature from a new Mail object content
    # See https://gitlab.com/gitlab-org/gitlab/issues/197386
    p7_re_enc = Gitlab::Email::Smime::Signer.verify_signature(
      ca_certs: root_certificate.cert,
      signed_data: Mail.new(mail).encoded)

    expect(p7_re_enc).not_to be_nil

    # envelope in a Mail object and obtain the body
    decoded_mail = Mail.new(p7enc.data)

    expect(decoded_mail.body.decoded.dup.force_encoding(decoded_mail.charset)).to eq(mail_body)
  end
end
