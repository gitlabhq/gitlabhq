# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Smime::Signer do
  include SmimeHelper

  let_it_be(:root_ca) { generate_root }
  let_it_be(:intermediate_ca) { generate_intermediate(signer_ca: root_ca) }

  context 'when using an intermediate CA' do
    it 'signs data appropriately with SMIME' do
      cert = generate_cert(signer_ca: intermediate_ca)

      sign_and_verify('signed content', cert[:cert], cert[:key], root_ca[:cert], ca_certs: intermediate_ca[:cert])
    end
  end

  context 'when not using an intermediate CA' do
    it 'signs data appropriately with SMIME' do
      cert = generate_cert(signer_ca: root_ca)

      sign_and_verify('signed content', cert[:cert], cert[:key], root_ca[:cert])
    end
  end

  def sign_and_verify(data, cert, key, root_ca_cert, ca_certs: nil)
    signed_content = described_class.sign(
      cert: cert,
      key: key,
      ca_certs: ca_certs,
      data: data)

    expect(signed_content).not_to be_nil

    p7enc = described_class.verify_signature(
      ca_certs: root_ca_cert,
      signed_data: signed_content)

    expect(p7enc).not_to be_nil
    expect(p7enc.data).to eq(data)
  end
end
