# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CreateModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:existing_model) { create(:ml_models) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:description) { 'description' }
  let_it_be(:metadata) { [] }

  before do
    allow(Gitlab::InternalEvents).to receive(:track_event)
  end

  subject(:create_model) { described_class.new(project, name, user, description, metadata).execute }

  describe '#execute' do
    context 'when model name does not exist in the project' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }

      it 'creates a model', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(1)
        expect(Gitlab::InternalEvents).to have_received(:track_event).with(
          'model_registry_ml_model_created',
          { project: project, user: user }
        )

        expect(create_model.name).to eq(name)
      end
    end

    context 'when model name exists but project is different' do
      let(:name) { existing_model.name }
      let(:project) { another_project }

      it 'creates a model', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(1)
        expect(Gitlab::InternalEvents).to have_received(:track_event).with(
          'model_registry_ml_model_created',
          { project: project, user: user }
        )

        expect(create_model.name).to eq(name)
      end
    end

    context 'when model with name exists' do
      let(:name) { existing_model.name }
      let(:project) { existing_model.project }

      it 'raises an error', :aggregate_failures do
        expect { create_model }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Gitlab::InternalEvents).not_to have_received(:track_event)
      end
    end

    context 'when metadata are supplied, add them as metadata' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: 'key2', value: 'value2' }] }

      it 'creates metadata records', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(1)

        expect(create_model.name).to eq(name)
        expect(create_model.metadata.count).to be 2
      end
    end

    # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
    context 'for metadata with duplicate keys, it does not create duplicate records' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: 'key1', value: 'value2' }] }

      it 'raises an error', :aggregate_failures do
        expect { create_model }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
    context 'for metadata with invalid keys, it does not create invalid records' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: '', value: 'value2' }] }

      it 'raises an error', :aggregate_failures do
        expect { create_model }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
