# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceSettings::UpdateService, feature_category: :pipeline_composition do
  let(:settings) { instance_double(NamespaceSetting) }
  let(:args) { { pipeline_variables_default_role: 'developer' } }
  let(:errors) { instance_double(ActiveModel::Errors, full_messages: ['Error message']) }

  subject(:service) { described_class.new(settings, args) }

  describe '#execute' do
    context 'when update is successful' do
      before do
        allow(settings).to receive(:update).with(args).and_return(true)
      end

      it 'returns success response' do
        expect(service.execute).to be_success
      end
    end

    context 'when update fails' do
      before do
        allow(settings).to receive(:update).with(args).and_return(false)
        allow(settings).to receive(:errors).and_return(errors)
      end

      it 'returns error response' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq(['Error message'])
      end
    end

    context 'with real data' do
      let(:namespace) { create(:group, :public) }
      let(:settings) { namespace.namespace_settings }

      it 'updates settings successfully' do
        response = service.execute

        expect(response).to be_success
        expect(settings.reload.pipeline_variables_default_role).to eq('developer')
      end

      context 'with invalid data' do
        let(:args) { { pipeline_variables_default_role: 'invalid_role' } }

        it 'returns error response' do
          response = service.execute

          expect(response).to be_error
          expect(response.message).to be_present
        end
      end
    end
  end
end
