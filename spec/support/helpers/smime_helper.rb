# frozen_string_literal: true

module SmimeHelper
  INFINITE_EXPIRY = 1000.years
  SHORT_EXPIRY = 30.minutes

  def generate_root
    issue(cn: 'RootCA', signed_by: nil, expires_in: INFINITE_EXPIRY, certificate_authority: true)
  end

  def generate_intermediate(signer_ca:)
    issue(cn: 'IntermediateCA', signed_by: signer_ca, expires_in: INFINITE_EXPIRY, certificate_authority: true)
  end

  def generate_cert(signer_ca:, expires_in: SHORT_EXPIRY)
    issue(signed_by: signer_ca, expires_in: expires_in, certificate_authority: false)
  end

  # returns a hash { key:, cert: } containing a generated key, cert pair
  def issue(signed_by:, expires_in:, certificate_authority:, email_address: 'test@example.com', cn: nil)
    key = OpenSSL::PKey::RSA.new(4096)
    public_key = key.public_key

    subject = if certificate_authority
                OpenSSL::X509::Name.parse("/CN=#{cn}")
              else
                OpenSSL::X509::Name.parse("/CN=#{email_address}")
              end

    cert = OpenSSL::X509::Certificate.new
    cert.subject = subject

    cert.issuer = signed_by&.fetch(:cert, nil)&.subject || subject

    cert.not_before = Time.now
    cert.not_after = expires_in.from_now
    cert.public_key = public_key
    cert.serial = 0x0
    cert.version = 2

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    if certificate_authority
      extension_factory.subject_certificate = cert
      extension_factory.issuer_certificate = cert
      cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
      cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
      cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))
    else
      cert.add_extension(extension_factory.create_extension('subjectAltName', "email:#{email_address}", false))
      cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:FALSE', true))
      cert.add_extension(extension_factory.create_extension('keyUsage', 'digitalSignature,keyEncipherment', true))
      cert.add_extension(extension_factory.create_extension('extendedKeyUsage', 'clientAuth,emailProtection', false))
    end

    cert.sign(signed_by&.fetch(:key, nil) || key, OpenSSL::Digest.new('SHA256'))

    { key: key, cert: cert }
  end
end
