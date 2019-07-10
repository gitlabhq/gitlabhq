# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Smime::Signer do
  include SmimeHelper

  it 'signs data appropriately with SMIME' do
    root_certificate = generate_root
    certificate = generate_cert(root_ca: root_certificate)

    signed_content = described_class.sign(
      cert: certificate[:cert],
      key: certificate[:key],
      data: 'signed content')
    expect(signed_content).not_to be_nil

    p7enc = described_class.verify_signature(
      cert: certificate[:cert],
      ca_cert: root_certificate[:cert],
      signed_data: signed_content)

    expect(p7enc).not_to be_nil
    expect(p7enc.data).to eq('signed content')
  end
end
