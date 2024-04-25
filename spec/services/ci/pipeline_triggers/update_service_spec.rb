# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggers::UpdateService, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be_with_reload(:user) { create(:user, maintainer_of: project) }
  let_it_be(:another_maintainer) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:pipeline_trigger) do
    create(:ci_trigger, project: project, owner: user, description: "Old description")
  end

  subject(:service) { described_class.new(user: user, trigger: pipeline_trigger, description: description) }

  before_all do
    pipeline_trigger.reload
  end

  describe "execute" do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(trigger: pipeline_trigger, user: another_maintainer, description: {}) }

      it 'returns ServiceResponse.error' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.error?).to be(true)

        error_message = _('The current user is not authorized to update the pipeline trigger token')
        expect(response.message).to eq(error_message)
        expect(response.errors).to match_array([error_message])
      end
    end

    context 'when user has permission' do
      let(:description) { 'My updated description' }

      it 'updates database values with passed description param' do
        expect { service.execute }
          .to change { pipeline_trigger.reload.description }.from('Old description').to('My updated description')
      end

      it 'returns ServiceResponse.success' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.success?).to be(true)
        expect(response.payload[:trigger].description).to eq('My updated description')
      end

      context 'when update fails' do
        before do
          allow(pipeline_trigger).to receive(:update).and_return(false)
        end

        it 'returns ServiceResponse.error' do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response.error?).to be(true)
          expect(response.message).to eq('Attempted to update the pipeline trigger token but failed')
        end
      end
    end
  end
end
