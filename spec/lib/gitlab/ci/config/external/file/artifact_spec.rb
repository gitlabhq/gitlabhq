# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Artifact, feature_category: :pipeline_composition do
  let(:parent_pipeline) { create(:ci_pipeline) }
  let(:project) { parent_pipeline.project }
  let(:variables) {}
  let(:context) do
    Gitlab::Ci::Config::External::Context
      .new(variables: variables, parent_pipeline: parent_pipeline, project: project)
  end

  let(:external_file) { described_class.new(params, context) }

  describe '#matching?' do
    context 'when params contain artifact location' do
      let(:params) { { artifact: 'generated.yml' } }

      it 'returns true' do
        expect(external_file).to be_matching
      end
    end

    context 'when params does not contain artifact location' do
      let(:params) { {} }

      it 'returns false' do
        expect(external_file).not_to be_matching
      end
    end
  end

  describe '#valid?' do
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([external_file])
      external_file.valid?
    end

    shared_examples 'is invalid' do
      it 'sets the expected error' do
        expect(valid?).to be_falsy
        expect(external_file.errors).to contain_exactly(expected_error)
        expect(external_file.content).to eq(nil)
      end
    end

    describe 'when used in non child pipeline context' do
      let(:context) { Gitlab::Ci::Config::External::Context.new }
      let(:params) { { artifact: 'generated.yml' } }

      let(:expected_error) do
        'Including configs from artifacts is only allowed when triggering child pipelines'
      end

      it_behaves_like 'is invalid'
    end

    context 'when used in child pipeline context' do
      let(:parent_pipeline) { create(:ci_pipeline) }

      context 'when job is not provided' do
        let(:params) { { artifact: 'generated.yml' } }

        let(:expected_error) do
          'Job must be provided when including configs from artifacts'
        end

        it_behaves_like 'is invalid'
      end

      context 'when job is provided' do
        let(:params) { { artifact: 'generated.yml', job: 'generator' } }

        context 'when job does not exist in the parent pipeline' do
          let(:expected_error) do
            'Job `generator` not found in parent pipeline or does not have artifacts!'
          end

          it_behaves_like 'is invalid'
        end

        context 'when job exists in the parent pipeline' do
          let!(:generator_job) { create(:ci_build, name: 'generator', pipeline: parent_pipeline) }

          context 'when job does not have artifacts' do
            let(:expected_error) do
              'Job `generator` not found in parent pipeline or does not have artifacts!'
            end

            it_behaves_like 'is invalid'
          end

          context 'when job has archive artifacts' do
            let!(:artifacts) do
              create(:ci_job_artifact, :archive,
                job: generator_job,
                file: fixture_file_upload(Rails.root.join('spec/fixtures/pages.zip'), 'application/zip'))
            end

            let(:expected_error) do
              "Job `generator` (#{generator_job.id}) has missing artifacts metadata and cannot be extracted!"
            end

            it_behaves_like 'is invalid'

            context 'when job has artifacts exceeding the max allowed size' do
              let(:expected_error) do
                "Artifacts archive for job `generator` is too large: 2.28 KiB exceeds maximum of 1 KiB"
              end

              before do
                stub_application_setting(max_artifacts_content_include_size: 1.kilobyte)
              end

              it_behaves_like 'is invalid'
            end

            context 'when job has artifacts metadata' do
              let!(:metadata) do
                create(:ci_job_artifact, :metadata, job: generator_job)
              end

              let(:expected_error) do
                'Path `generated.yml` does not exist inside the `generator` artifacts archive!'
              end

              it_behaves_like 'is invalid'

              context 'when file is found in metadata' do
                let!(:artifacts) { create(:ci_job_artifact, :archive, job: generator_job) }
                let!(:metadata) { create(:ci_job_artifact, :metadata, job: generator_job) }

                context 'when file is empty' do
                  let(:params) { { artifact: 'secret_stuff/generated.yml', job: 'generator' } }
                  let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_stuff', 'masked' => true }]) }
                  let(:context) do
                    Gitlab::Ci::Config::External::Context.new(parent_pipeline: parent_pipeline, variables: variables)
                  end

                  before do
                    allow_next_instance_of(Gitlab::Ci::ArtifactFileReader) do |reader|
                      allow(reader).to receive(:read).and_return(nil)
                    end
                  end

                  let(:expected_error) do
                    'File `[MASKED]xxxx/generated.yml` is empty!'
                  end

                  it_behaves_like 'is invalid'
                end

                context 'when file is not empty' do
                  it 'is valid' do
                    expect(valid?).to be_truthy
                    expect(external_file.content).to be_present
                  end

                  it 'propagates parent_pipeline to nested includes' do
                    expected_attrs = {
                      parent_pipeline: parent_pipeline,
                      project: anything,
                      sha: anything,
                      user: anything
                    }
                    expect(context).to receive(:mutate).with(expected_attrs).and_call_original

                    external_file.content
                    expect(valid?).to be_truthy
                  end
                end
              end
            end
          end
        end
      end

      context 'when job is provided as a variable' do
        let(:variables) do
          Gitlab::Ci::Variables::Collection.new(
            [
              { key: 'VAR1', value: 'a_secret_variable_value', masked: true }
            ])
        end

        let(:params) { { artifact: 'generated.yml', job: 'a_secret_variable_value' } }

        context 'when job does not exist in the parent pipeline' do
          let(:expected_error) do
            'Job `[MASKED]xxxxxxxxxxxxxxx` not found in parent pipeline or does not have artifacts!'
          end

          it_behaves_like 'is invalid'
        end
      end
    end
  end

  describe '#metadata' do
    let(:params) { { artifact: 'generated.yml' } }

    subject(:metadata) { external_file.metadata }

    it do
      is_expected.to eq(
        context_project: project.full_path,
        context_sha: nil,
        type: :artifact,
        location: 'generated.yml',
        extra: { job_name: nil }
      )
    end

    context 'when job name includes a masked variable' do
      let(:variables) do
        Gitlab::Ci::Variables::Collection.new([{ key: 'VAR1', value: 'a_secret_variable_value', masked: true }])
      end

      let(:params) { { artifact: 'generated.yml', job: 'a_secret_variable_value' } }

      it do
        is_expected.to eq(
          context_project: project.full_path,
          context_sha: nil,
          type: :artifact,
          location: 'generated.yml',
          extra: { job_name: '[MASKED]xxxxxxxxxxxxxxx' }
        )
      end
    end
  end

  describe '#to_hash' do
    context 'when interpolation is being used' do
      let!(:job) { create(:ci_build, name: 'generator', pipeline: parent_pipeline) }
      let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
      let!(:metadata) { create(:ci_job_artifact, :metadata, job: job) }

      before do
        allow_next_instance_of(Gitlab::Ci::ArtifactFileReader) do |reader|
          allow(reader).to receive(:read).and_return(template)
        end
      end

      let(:template) do
        <<~YAML
        spec:
          inputs:
            env:
        ---
        deploy:
          script: deploy $[[ inputs.env ]]
        YAML
      end

      let(:params) { { artifact: 'generated.yml', job: 'generator', inputs: { env: 'production' } } }

      it 'correctly interpolates content' do
        expect(external_file.to_hash).to eq({ deploy: { script: 'deploy production' } })
      end
    end
  end
end
