# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ServiceDeskSettings::UpdateService do
  describe '#execute' do
    let_it_be(:settings) { create(:service_desk_setting, outgoing_name: 'original name') }
    let_it_be(:user) { create(:user) }

    context 'with valid params' do
      let(:params) { { outgoing_name: 'some name', project_key: 'foo' } }

      it 'updates service desk settings' do
        result = described_class.new(settings.project, user, params).execute

        expect(result[:status]).to eq :success
        expect(settings.reload.outgoing_name).to eq 'some name'
        expect(settings.reload.project_key).to eq 'foo'
      end

      context 'when service_desk_custom_address is disabled' do
        before do
          stub_feature_flags(service_desk_custom_address: false)
        end

        it 'ignores project_key parameter' do
          result = described_class.new(settings.project, user, params).execute

          expect(result[:status]).to eq :success
          expect(settings.reload.project_key).to be_nil
        end
      end
    end

    context 'when project_key is an empty string' do
      let(:params) { { project_key: '' } }

      it 'sets nil project_key' do
        result = described_class.new(settings.project, user, params).execute

        expect(result[:status]).to eq :success
        expect(settings.reload.project_key).to be_nil
      end
    end

    context 'with invalid params' do
      let(:params) { { outgoing_name: 'x' * 256 } }

      it 'does not update service desk settings' do
        result = described_class.new(settings.project, user, params).execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'Outgoing name is too long (maximum is 255 characters)'
        expect(settings.reload.outgoing_name).to eq 'original name'
      end
    end
  end
end
