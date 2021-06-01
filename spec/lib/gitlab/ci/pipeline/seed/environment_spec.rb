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
      let(:expected_auto_stop_in_seconds) do
        if expected_auto_stop_in
          ChronicDuration.parse(expected_auto_stop_in).seconds
        end
      end

      it 'returns a persisted environment object' do
        freeze_time do
          expect { subject }.to change { Environment.count }.by(1)

          expect(subject).to be_a(Environment)
          expect(subject).to be_persisted
          expect(subject.project).to eq(project)
          expect(subject.name).to eq(expected_environment_name)
          expect(subject.auto_stop_in).to eq(expected_auto_stop_in_seconds)
        end
      end

      context 'when environment has already existed' do
        let!(:environment) do
          create(:environment,
            project: project,
            name: expected_environment_name
          ).tap do |env|
            env.auto_stop_in = expected_auto_stop_in
          end
        end

        it 'returns the existing environment object' do
          expect { subject }.not_to change { Environment.count }
          expect { subject }.not_to change { environment.auto_stop_at }

          expect(subject).to be_persisted
          expect(subject).to eq(environment)
        end
      end
    end

    context 'when job has environment name attribute' do
      let(:environment_name) { 'production' }
      let(:expected_environment_name) { 'production' }
      let(:expected_auto_stop_in) { nil }

      let(:attributes) do
        {
          environment: environment_name,
          options: { environment: { name: environment_name } }
        }
      end

      it_behaves_like 'returning a correct environment'

      context 'and job environment also has an auto_stop_in attribute' do
        let(:environment_auto_stop_in) { '5 minutes' }
        let(:expected_auto_stop_in) { '5 minutes' }

        let(:attributes) do
          {
            environment: environment_name,
            options: {
              environment: {
                name: environment_name,
                auto_stop_in: environment_auto_stop_in
              }
            }
          }
        end

        it_behaves_like 'returning a correct environment'
      end
    end

    context 'when job has deployment tier attribute' do
      let(:attributes) do
        {
          environment: 'customer-portal',
          options: {
            environment: {
              name: 'customer-portal',
              deployment_tier: deployment_tier
            }
          }
        }
      end

      let(:deployment_tier) { 'production' }

      context 'when environment has not been created yet' do
        it 'sets the specified deployment tier' do
          is_expected.to be_production
        end

        context 'when deployment tier is staging' do
          let(:deployment_tier) { 'staging' }

          it 'sets the specified deployment tier' do
            is_expected.to be_staging
          end
        end

        context 'when deployment tier is unknown' do
          let(:deployment_tier) { 'unknown' }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, "'unknown' is not a valid tier")
          end
        end
      end

      context 'when environment has already been created' do
        before do
          create(:environment, project: project, name: 'customer-portal', tier: :staging)
        end

        it 'does not overwrite the specified deployment tier' do
          # This is to be updated when a deployment succeeded i.e. Deployments::UpdateEnvironmentService.
          is_expected.to be_staging
        end
      end
    end

    context 'when job starts a review app' do
      let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
      let(:expected_environment_name) { "review/#{job.ref}" }
      let(:expected_auto_stop_in) { nil }

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
      let(:expected_auto_stop_in) { nil }

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
