require 'spec_helper'

describe Gitlab::FakeApplicationSettings do
  let(:defaults) { { password_authentication_enabled_for_web: false, foobar: 'asdf', signup_enabled: true, 'test?' => 123 } }

  subject { described_class.new(defaults) }

  it 'wraps OpenStruct variables properly' do
    expect(subject.password_authentication_enabled_for_web).to be_falsey
    expect(subject.signup_enabled).to be_truthy
    expect(subject.foobar).to eq('asdf')
  end

  it 'defines predicate methods' do
    expect(subject.password_authentication_enabled_for_web?).to be_falsey
    expect(subject.signup_enabled?).to be_truthy
  end

  it 'predicate method changes when value is updated' do
    subject.password_authentication_enabled_for_web = true

    expect(subject.password_authentication_enabled_for_web?).to be_truthy
  end

  it 'does not define a predicate method' do
    expect(subject.foobar?).to be_nil
  end

  it 'does not override an existing predicate method' do
    expect(subject.test?).to eq(123)
  end
end
