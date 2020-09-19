# frozen_string_literal: true

RSpec.shared_examples 'an atlassian identity' do
  it 'sets the proper values' do
    expect(identity.extern_uid).to eq(extern_uid)
    expect(identity.token).to eq(credentials[:token])
    expect(identity.refresh_token).to eq(credentials[:refresh_token])
    expect(identity.expires_at.to_i).to eq(credentials[:expires_at])
  end
end
