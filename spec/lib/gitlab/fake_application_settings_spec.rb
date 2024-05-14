# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FakeApplicationSettings do
  let(:defaults) do
    described_class.defaults.merge(
      foobar: 'asdf',
      test?: 123,
      # these two settings have no default in ApplicationSettingImplementation,
      # so we need to set one here
      domain_denylist: [],
      archive_builds_in_seconds: nil
    )
  end

  let(:setting) { described_class.new(defaults) }

  it 'defines methods for default attributes' do
    expect(setting.password_authentication_enabled_for_web).to be_truthy
    expect(setting.signup_enabled).to be_truthy
    expect(setting.foobar).to eq('asdf')
  end

  it 'defines predicate methods for boolean properties' do
    expect(setting.password_authentication_enabled_for_web?).to be_truthy
    expect(setting.signup_enabled?).to be_truthy
  end

  it 'does not define a predicate method for non-boolean properties' do
    expect(setting.foobar?).to be_nil
  end

  it 'returns nil for undefined attributes' do
    expect(setting.does_not_exist).to be_nil
  end

  it 'does not override an existing predicate method' do
    expect(setting.test?).to eq(123)
  end

  it_behaves_like 'application settings examples'
end
