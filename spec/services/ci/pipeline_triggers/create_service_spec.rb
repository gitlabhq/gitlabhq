# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggers::CreateService, feature_category: :continuous_integration do
  let_it_be(:developer) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, maintainers: user, developers: developer) }

  subject(:service) do
    described_class.new(project: project, user: user, description: description, expires_at: expires_at)
  end

  describe "execute" do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(project: project, user: developer, description: {}) }

      it 'returns ServiceResponse.error' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.error?).to be(true)

        error_message = _('The current user is not authorized to create a pipeline trigger token')
        expect(response.message).to eq(error_message)
        expect(response.errors).to match_array([error_message])
      end
    end

    context 'when user has permission' do
      let(:description) { "My snazzy pipeline trigger token" }
      let(:expires_at) { DateTime.now + 2.weeks }

      it 'creates a pipeline trigger token' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.success?).to be(true)
        trigger = response.payload[:trigger]
        expect(trigger).to be_a(Ci::Trigger)
        expect(trigger).to be_persisted
        expect(trigger.description).to eq(description)
        expect(trigger.expires_at).to eq(expires_at)
        expect(trigger.owner).to eq(user)
        expect(trigger.project).to eq(project)
      end

      context 'when create fails' do
        before do
          allow(project.triggers).to receive(:create).and_return(nil)
        end

        it 'raises a RuntimeError' do
          expect { service.execute }.to raise_error(RuntimeError, /Unexpected Ci::Trigger creation failure/)
        end
      end

      context 'when trigger exists but has errors' do
        before do
          trigger_with_errors = instance_double('Ci::Trigger', present?: true, persisted?: false,
            errors: ['Validation error'])
          allow(project.triggers).to receive(:create).and_return(trigger_with_errors)
        end

        it 'returns ServiceResponse.error' do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response.error?).to be(true)
          expect(response.message).to eq('["Validation error"]')
          expect(response.reason).to eq(:validation_error)
        end
      end

      context 'when expiration beyond max expiration date' do
        let(:expires_at) { DateTime.now + 100.years }

        max_expiry_date = Date.current.advance(days: PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS)
        error_text = format(_("must be before %{expiry_date}"), expiry_date: max_expiry_date)

        it 'fails validation when trigger_token_expiration feature flag on' do
          stub_feature_flags(trigger_token_expiration: true)

          response = service.execute

          expect(response.error?).to be(true)
          expect(Gitlab::Json.parse(response.errors[0])['expires_at'][0]).to eq(error_text)
        end

        it 'passes validation when trigger_token_expiration feature flag off' do
          stub_feature_flags(trigger_token_expiration: false)

          response = service.execute

          expect(response.success?).to be(true)
        end
      end
    end
  end
end
