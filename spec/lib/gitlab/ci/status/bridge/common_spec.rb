# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Bridge::Common, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:bridge) { create(:ci_bridge) }
  let_it_be(:downstream_pipeline) { create(:ci_pipeline) }

  before_all do
    create(:ci_sources_pipeline,
      source_pipeline: bridge.pipeline,
      source_project: bridge.pipeline.project,
      source_job: bridge,
      pipeline: downstream_pipeline,
      project: downstream_pipeline.project)
  end

  subject do
    Gitlab::Ci::Status::Core
      .new(bridge, user)
      .extend(described_class)
  end

  describe '#details_path' do
    context 'when user has access to read downstream pipeline' do
      before do
        downstream_pipeline.project.add_developer(user)
      end

      it { expect(subject).to have_details }
      it { expect(subject.details_path).to include "pipelines/#{downstream_pipeline.id}" }
    end

    context 'when user does not have access to read downstream pipeline' do
      it { expect(subject).not_to have_details }
      it { expect(subject.details_path).to be_nil }
    end
  end

  describe '#label' do
    let(:description) { 'my description' }
    let(:bridge) { create(:ci_bridge, description: description) }

    subject do
      Gitlab::Ci::Status::Created
        .new(bridge, user)
        .extend(described_class)
    end

    it 'returns description' do
      expect(subject.label).to eq description
    end

    context 'when description is nil' do
      let(:description) { nil }

      it 'returns core status label' do
        expect(subject.label).to eq('created')
      end
    end

    context 'when description is empty string' do
      let(:description) { '' }

      it 'returns core status label' do
        expect(subject.label).to eq('created')
      end
    end
  end
end
