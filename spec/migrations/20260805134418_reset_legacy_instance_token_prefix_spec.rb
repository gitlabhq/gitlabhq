# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetLegacyInstanceTokenPrefix, migration: :gitlab_main, feature_category: :system_access do
  let(:application_settings) { table(:application_settings) }

  it 'resets only the legacy "gl" value and leaves other values untouched' do
    legacy_row = application_settings.create!(token_prefixes: { 'instance_token_prefix' => 'gl' })
    custom_row = application_settings.create!(token_prefixes: { 'instance_token_prefix' => 'acme' })
    empty_row  = application_settings.create!(token_prefixes: { 'instance_token_prefix' => '' })
    absent_row = application_settings.create!(token_prefixes: {})

    migrate!

    expect(legacy_row.reload.token_prefixes['instance_token_prefix']).to eq('')
    expect(custom_row.reload.token_prefixes['instance_token_prefix']).to eq('acme')
    expect(empty_row.reload.token_prefixes['instance_token_prefix']).to eq('')
    expect(absent_row.reload.token_prefixes).to eq({})
  end
end
