# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails asset host initializer' do
  def load_initializer
    load Rails.root.join('config/initializers/rails_asset_host.rb')
  end

  around do |example|
    old_asset_host = Rails.application.config.action_controller.asset_host

    example.run

    Rails.application.config.action_controller.asset_host = old_asset_host
    ActionController::Base.asset_host = old_asset_host
  end

  subject { Rails.application.config.action_controller.asset_host }

  it 'uses no asset host by default' do
    load_initializer

    expect(subject).to be nil
  end

  context 'with cdn_host defined in gitlab.yml' do
    before do
      stub_config_setting(cdn_host: 'https://gitlab.example.com')
    end

    it 'returns https://gitlab.example.com' do
      load_initializer

      expect(subject).to eq('https://gitlab.example.com')
    end
  end
end
