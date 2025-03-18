# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::UpdateMetadataService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project, created_at: 1.day.ago) }

  let(:params) { { name: name } }
  let(:name) { 'Some random pipeline name' }

  subject(:execute) { described_class.new(pipeline, current_user: user, params: params).execute }

  describe '#execute' do
    context 'when user is authorized' do
      before_all do
        project.add_maintainer(user)
      end

      context 'when pipeline has no name' do
        it 'updates the name' do
          expect { execute }.to change { pipeline.reload.name }.to(name)
        end
      end

      context 'when pipeline has a name' do
        let_it_be(:pipeline) { create(:ci_pipeline, project: project, name: 'Some other name') }

        it 'updates the name' do
          expect { execute }.to change { pipeline.reload.name }.to(name)
        end
      end

      context 'when new name is too long' do
        let(:name) { 'a' * 256 }

        it 'does not update the name' do
          expect { execute }.not_to change { pipeline.reload.name }
        end
      end

      context 'when the pipeline is archived' do
        before do
          stub_application_setting(archive_builds_in_seconds: 3600)
        end

        it 'responds with forbidden' do
          response = execute

          expect(response).to be_error
          expect(response.reason).to eq(:forbidden)
        end
      end
    end

    context 'when user is not authorized' do
      it 'responds with forbidden' do
        response = execute

        expect(response).to be_error
        expect(response.reason).to eq(:forbidden)
      end
    end
  end
end
