# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Doorkeeper::Application, type: :model, feature_category: :system_access do
  let(:application) { create(:oauth_application) }

  it 'uses a prefixed secret' do
    expect(application.plaintext_secret).to match(/gloas-\h{64}/)
  end

  it 'allows dynamic scopes' do
    application.scopes = 'api user:*'
    expect(application).to be_valid
  end
end
