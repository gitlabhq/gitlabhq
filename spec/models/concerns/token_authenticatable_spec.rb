require 'spec_helper'

shared_examples 'TokenAuthenticatable' do
  describe 'dynamically defined methods' do
    it { expect(described_class).to be_private_method_defined(:generate_token) }
    it { expect(described_class).to be_private_method_defined(:write_new_token) }
    it { expect(described_class).to respond_to("find_by_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}") }
    it { is_expected.to respond_to("set_#{token_field}") }
    it { is_expected.to respond_to("reset_#{token_field}!") }
  end
end

describe User, 'TokenAuthenticatable' do
  let(:token_field) { :rss_token }
  it_behaves_like 'TokenAuthenticatable'

  describe 'ensures authentication token' do
    subject { create(:user).send(token_field) }
    it { is_expected.to be_a String }
  end
end

describe ApplicationSetting, 'TokenAuthenticatable' do
  let(:token_field) { :runners_registration_token }
  it_behaves_like 'TokenAuthenticatable'

  describe 'generating new token' do
    context 'token is not generated yet' do
      describe 'token field accessor' do
        subject { described_class.new.send(token_field) }
        it { is_expected.not_to be_blank }
      end

      describe 'ensured token' do
        subject { described_class.new.send("ensure_#{token_field}") }

        it { is_expected.to be_a String }
        it { is_expected.not_to be_blank }
      end

      describe 'ensured! token' do
        subject { described_class.new.send("ensure_#{token_field}!") }

        it 'persists new token' do
          expect(subject).to eq described_class.current[token_field]
        end
      end
    end

    context 'token is generated' do
      before do
        subject.send("reset_#{token_field}!")
      end

      it 'persists a new token' do
        expect(subject.send(:read_attribute, token_field)).to be_a String
      end
    end
  end

  describe 'setting new token' do
    subject { described_class.new.send("set_#{token_field}", '0123456789') }

    it { is_expected.to eq '0123456789' }
  end

  describe 'multiple token fields' do
    before do
      described_class.send(:add_authentication_token_field, :yet_another_token)
    end

    describe '.token_fields' do
      subject { described_class.authentication_token_fields }
      it { is_expected.to include(:runners_registration_token, :yet_another_token) }
    end
  end
end
