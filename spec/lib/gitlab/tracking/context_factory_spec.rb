# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ContextFactory, feature_category: :service_ping do
  describe '.for_frontend' do
    let(:user) { build_stubbed(:user) }
    let(:namespace) { build_stubbed(:group) }
    let(:project_id) { 42 }
    let(:extra_params) { { extra_key: 'extra_value' } }

    subject(:result) do
      described_class.for_frontend(
        user: user,
        namespace: namespace,
        project_id: project_id,
        **extra_params
      )
    end

    context 'when user is authenticated' do
      let(:standard_context) { instance_double(Gitlab::Tracking::StandardContext) }

      before do
        allow(Gitlab::Tracking::StandardContext).to receive(:new).and_return(standard_context)
      end

      it 'returns a StandardContext' do
        expect(result).to eq(standard_context)
      end

      it 'initializes StandardContext with provided parameters' do
        result

        expect(Gitlab::Tracking::StandardContext).to have_received(:new).with(
          user: user,
          namespace: namespace,
          project_id: project_id,
          **extra_params
        )
      end
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it 'returns a FrontendStandardContext wrapping StandardContext' do
        expect(result).to be_a(Gitlab::Tracking::FrontendStandardContext)
      end

      it 'filters sensitive fields from the context' do
        context_data = result.to_context.to_json[:data]

        Gitlab::Tracking::FrontendStandardContext::SENSITIVE_FIELDS.each do |field|
          expect(context_data).not_to have_key(field)
        end
      end

      it 'includes non-sensitive fields in the context' do
        context_data = result.to_context.to_json[:data]

        expect(context_data).to have_key(:environment)
        expect(context_data).to have_key(:source)
        expect(context_data).to have_key(:project_id)
        expect(context_data[:project_id]).to eq(project_id)
        expect(context_data[:extra]).to include(extra_key: 'extra_value')
      end
    end
  end
end
