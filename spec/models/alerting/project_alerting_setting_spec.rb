# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alerting::ProjectAlertingSetting do
  let_it_be(:project) { create(:project) }

  subject { create(:project_alerting_setting, project: project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe '#token' do
    context 'when set' do
      let(:token) { SecureRandom.hex }

      subject do
        create(:project_alerting_setting, project: project, token: token)
      end

      it 'reads the token' do
        expect(subject.token).to eq(token)
        expect(subject.encrypted_token).not_to be_nil
        expect(subject.encrypted_token_iv).not_to be_nil
      end
    end

    context 'when not set' do
      before do
        subject.token = nil
      end

      it 'generates a token before validation' do
        expect(subject).to be_valid
        expect(subject.token).to match(/\A\h{32}\z/)
      end
    end
  end
end
