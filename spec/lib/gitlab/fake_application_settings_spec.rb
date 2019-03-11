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

  describe '#commit_email_hostname' do
    context 'when the value is provided' do
      let(:defaults) { { commit_email_hostname: 'localhost' } }

      it 'returns the provided value' do
        expect(subject.commit_email_hostname).to eq('localhost')
      end
    end

    context 'when the value is not provided' do
      it 'returns the default from the class' do
        expect(subject.commit_email_hostname)
          .to eq(described_class.default_commit_email_hostname)
      end
    end
  end

  describe '#usage_ping_enabled' do
    context 'when usage ping can be configured' do
      before do
        allow(Settings.gitlab)
          .to receive(:usage_ping_enabled).and_return(true)
      end

      it 'returns the value provided' do
        subject.usage_ping_enabled = true

        expect(subject.usage_ping_enabled).to eq(true)

        subject.usage_ping_enabled = false

        expect(subject.usage_ping_enabled).to eq(false)
      end
    end

    context 'when usage ping cannot be configured' do
      before do
        allow(Settings.gitlab)
          .to receive(:usage_ping_enabled).and_return(false)
      end

      it 'always returns false' do
        subject.usage_ping_enabled = true

        expect(subject.usage_ping_enabled).to eq(false)

        subject.usage_ping_enabled = false

        expect(subject.usage_ping_enabled).to eq(false)
      end
    end
  end
end
