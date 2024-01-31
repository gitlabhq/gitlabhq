# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggers::DestroyService, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:developer) { create(:user) }
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project) }

    let(:pipeline_trigger) { create(:ci_trigger, project: project, owner: user) }

    subject(:service) { described_class.new(user: user, trigger: pipeline_trigger) }

    before_all do
      project.add_maintainer(user)
      project.add_developer(developer)
    end

    context 'when user does not have permission' do
      subject(:service) { described_class.new(user: developer, trigger: pipeline_trigger) }

      it 'returns an error' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.error?).to be(true)

        error_message = _('The current user is not authorized to manage the pipeline trigger token')
        expect(response.message).to eq(error_message)
        expect(response.errors).to match_array([error_message])
      end
    end

    context 'when user has permission' do
      it 'deletes the pipeline trigger token' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response.success?).to be(true)
        expect(Ci::Trigger.find_by(id: pipeline_trigger.id)).to be_nil
      end

      context 'when destroy fails' do
        before do
          allow(pipeline_trigger).to receive(:destroy).and_return(false)
        end

        it 'returns ServiceResponse.error' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Attempted to destroy the pipeline trigger token but failed')
        end
      end
    end
  end
end
