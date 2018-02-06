require 'spec_helper'

describe ChatNames::AuthorizeUserService do
  describe '#execute' do
    let(:service) { create(:service) }

    subject { described_class.new(service, params).execute }

    context 'when all parameters are valid' do
      let(:params) { { team_id: 'T0001', team_domain: 'myteam', user_id: 'U0001', user_name: 'user' } }

      it 'requests a new token' do
        is_expected.to be_url
      end
    end

    context 'when there are missing parameters' do
      let(:params) { {} }

      it 'does not request a new token' do
        is_expected.to be_nil
      end
    end
  end
end
