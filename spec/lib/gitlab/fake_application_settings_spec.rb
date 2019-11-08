# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::FakeApplicationSettings do
  let(:defaults) do
    described_class.defaults.merge(
      foobar: 'asdf',
      'test?' => 123
    )
  end

  let(:setting) { described_class.new(defaults) }

  it 'wraps OpenStruct variables properly' do
    expect(setting.password_authentication_enabled_for_web).to be_truthy
    expect(setting.signup_enabled).to be_truthy
    expect(setting.foobar).to eq('asdf')
  end

  it 'defines predicate methods' do
    expect(setting.password_authentication_enabled_for_web?).to be_truthy
    expect(setting.signup_enabled?).to be_truthy
  end

  it 'does not define a predicate method' do
    expect(setting.foobar?).to be_nil
  end

  it 'does not override an existing predicate method' do
    expect(setting.test?).to eq(123)
  end

  it_behaves_like 'application settings examples'
end
