# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggers::CreateService, feature_category: :continuous_integration do
  let_it_be(:developer) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }

  subject(:service) { described_class.new(project: project, user: user, description: description) }

  before_all do
    project.add_maintainer(user)
    project.add_developer(developer)
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

      it 'creates a pipeline trigger token' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.success?).to be(true)
        trigger = response.payload[:trigger]
        expect(trigger).to be_a(Ci::Trigger)
        expect(trigger).to be_persisted
        expect(trigger.description).to eq(description)
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
    end
  end
end
