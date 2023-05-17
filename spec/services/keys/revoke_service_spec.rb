# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::RevokeService, feature_category: :source_code_management do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  it 'destroys a key' do
    key = create(:key)

    expect { service.execute(key) }.to change { key.persisted? }.from(true).to(false)
  end

  it 'unverifies associated signatures' do
    key = create(:key)
    signature = create(:ssh_signature, key: key)

    expect do
      service.execute(key)
    end.to change { signature.reload.key }.from(key).to(nil)
      .and change { signature.reload.verification_status }.from('verified').to('revoked_key')
  end

  it 'does not unverifies signatures if destroy fails' do
    key = create(:key)
    signature = create(:ssh_signature, key: key)

    expect(key).to receive(:destroy).and_return(false)

    expect { service.execute(key) }.not_to change { signature.reload.verification_status }
    expect(key).to be_persisted
  end
end
