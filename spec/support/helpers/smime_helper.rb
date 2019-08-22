module SmimeHelper
  include OpenSSL

  INFINITE_EXPIRY = 1000.years
  SHORT_EXPIRY = 30.minutes

  def generate_root
    issue(signed_by: nil, expires_in: INFINITE_EXPIRY, certificate_authority: true)
  end

  def generate_cert(root_ca:, expires_in: SHORT_EXPIRY)
    issue(signed_by: root_ca, expires_in: expires_in, certificate_authority: false)
  end

  # returns a hash { key:, cert: } containing a generated key, cert pair
  def issue(email_address: 'test@example.com', signed_by:, expires_in:, certificate_authority:)
    key = OpenSSL::PKey::RSA.new(4096)
    public_key = key.public_key

    subject = if certificate_authority
                X509::Name.parse("/CN=EU")
              else
                X509::Name.parse("/CN=#{email_address}")
              end

    cert = X509::Certificate.new
    cert.subject = subject

    cert.issuer = signed_by&.fetch(:cert, nil)&.subject || subject

    cert.not_before = Time.now
    cert.not_after = expires_in.from_now
    cert.public_key = public_key
    cert.serial = 0x0
    cert.version = 2

    extension_factory = X509::ExtensionFactory.new
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

    cert.sign(signed_by&.fetch(:key, nil) || key, Digest::SHA256.new)

    { key: key, cert: cert }
  end
end
