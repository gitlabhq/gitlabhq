# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatNames::AuthorizeUserService, feature_category: :user_profile do
  describe '#execute' do
    let(:result) { subject.execute }

    subject { described_class.new(params) }

    context 'when all parameters are valid' do
      let(:params) { { team_id: 'T0001', team_domain: 'myteam', user_id: 'U0001', user_name: 'user' } }

      it 'produces a valid HTTP URL' do
        expect(result).to be_http_url
      end

      it 'requests a new token' do
        expect(subject).to receive(:request_token).once.and_call_original

        subject.execute
      end
    end

    context 'when there are missing parameters' do
      let(:params) { {} }

      it 'does not produce a URL' do
        expect(result).to be_nil
      end

      it 'does not request a new token' do
        expect(subject).not_to receive(:request_token)

        subject.execute
      end
    end
  end
end
