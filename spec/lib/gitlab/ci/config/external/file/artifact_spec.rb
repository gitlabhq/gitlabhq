# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Artifact do
  let(:parent_pipeline) { create(:ci_pipeline) }
  let(:context) do
    Gitlab::Ci::Config::External::Context.new(parent_pipeline: parent_pipeline)
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
    shared_examples 'is invalid' do
      it 'is not valid' do
        expect(external_file).not_to be_valid
      end

      it 'sets the expected error' do
        expect(external_file.errors)
          .to contain_exactly(expected_error)
      end
    end

    describe 'when used in non child pipeline context' do
      let(:parent_pipeline) { nil }
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
              'Job `generator` has missing artifacts metadata and cannot be extracted!'
            end

            it_behaves_like 'is invalid'

            context 'when job has artifacts exceeding the max allowed size' do
              let(:expected_error) do
                "Artifacts archive for job `generator` is too large: max 1 KB"
              end

              before do
                stub_const("#{Gitlab::Ci::ArtifactFileReader}::MAX_ARCHIVE_SIZE", 1.kilobyte)
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
                  before do
                    allow_next_instance_of(Gitlab::Ci::ArtifactFileReader) do |reader|
                      allow(reader).to receive(:read).and_return('')
                    end
                  end

                  let(:expected_error) do
                    'File `generated.yml` is empty!'
                  end

                  it_behaves_like 'is invalid'
                end

                context 'when file is not empty' do
                  it 'is valid' do
                    expect(external_file).to be_valid
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
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
