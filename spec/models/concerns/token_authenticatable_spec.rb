require 'spec_helper'

shared_examples 'TokenAuthenticatable' do
  describe 'dynamically defined methods' do
    it { expect(described_class).to be_private_method_defined(:generate_token_for) }
    it { expect(described_class).to respond_to("find_by_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}") }
    it { is_expected.to respond_to("reset_#{token_field}!") }
  end
end

describe User, 'TokenAuthenticatable' do
  let(:token_field) { :authentication_token }
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
    subject { described_class.new }
    let(:token) { subject.send(token_field) }

    context 'token is not generated yet' do
      it { expect(token).to be nil }

      describe 'ensured token' do
        subject { described_class.new.send("ensure_#{token_field}") }

        it { is_expected.to be_a String }
        it { is_expected.to_not be_blank }
      end
    end

    context 'token is generated' do
      before { subject.send("reset_#{token_field}!") }
      it { expect(token).to be_a String }
    end
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
