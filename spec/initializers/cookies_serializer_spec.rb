# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cookies serializer initializer' do
  def load_initializer
    load Rails.root.join('config/initializers/cookies_serializer.rb')
  end

  subject { Rails.application.config.action_dispatch.cookies_serializer }

  it 'uses JSON serializer by default' do
    load_initializer

    expect(subject).to eq(:json)
  end

  it 'uses the unsafe hybrid serializer when the environment variables is set' do
    stub_env('USE_UNSAFE_HYBRID_COOKIES', 'true')

    load_initializer

    expect(subject).to eq(:hybrid)
  end
end
