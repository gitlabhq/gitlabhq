# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Environment do
  let_it_be(:project) { create(:project) }
  let(:job) { build(:ci_build, project: project) }
  let(:seed) { described_class.new(job) }
  let(:attributes) { {} }

  before do
    job.assign_attributes(**attributes)
  end

  describe '#to_resource' do
    subject { seed.to_resource }

    shared_examples_for 'returning a correct environment' do
      it 'returns a persisted environment object' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(subject).to be_a(Environment)
        expect(subject).to be_persisted
        expect(subject.project).to eq(project)
        expect(subject.name).to eq(expected_environment_name)
      end

      context 'when environment has already existed' do
        let!(:environment) { create(:environment, project: project, name: expected_environment_name) }

        it 'returns the existing environment object' do
          expect { subject }.not_to change { Environment.count }

          expect(subject).to be_persisted
          expect(subject).to eq(environment)
        end
      end
    end

    context 'when job has environment attribute' do
      let(:environment_name) { 'production' }
      let(:expected_environment_name) { 'production' }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name } }
        }
      end

      it_behaves_like 'returning a correct environment'
    end

    context 'when job starts a review app' do
      let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
      let(:expected_environment_name) { "review/#{job.ref}" }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name } }
        }
      end

      it_behaves_like 'returning a correct environment'
    end

    context 'when job stops a review app' do
      let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
      let(:expected_environment_name) { "review/#{job.ref}" }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name, action: 'stop' } }
        }
      end

      it_behaves_like 'returning a correct environment'
    end
  end
end
