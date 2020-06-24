# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserEntity do
  include Gitlab::Routing

  let(:entity) { described_class.new(user) }
  let(:user) { create(:user) }

  subject { entity.as_json }

  it 'exposes user name and login' do
    expect(subject).to include(:username, :name)
  end

  it 'does not expose passwords' do
    expect(subject).not_to include(/password/)
  end

  it 'does not expose tokens' do
    expect(subject).not_to include(/token/)
  end

  it 'does not expose 2FA OTPs' do
    expect(subject).not_to include(/otp/)
  end

  it 'exposes user path' do
    expect(subject[:path]).to eq user_path(user)
  end
end
