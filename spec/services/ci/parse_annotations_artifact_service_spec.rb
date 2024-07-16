# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ParseAnnotationsArtifactService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project) }

  let_it_be_with_reload(:build) { create(:ci_build, project: project) }
  let(:service) { described_class.new(project, nil) }

  describe '#execute' do
    subject { service.execute(artifact) }

    context 'when build has an annotations artifact' do
      let_it_be(:artifact) { create(:ci_job_artifact, :annotations, job: build) }

      context 'when artifact does not have the specified blob' do
        before do
          allow(artifact).to receive(:each_blob)
        end

        it 'parses nothing' do
          expect(subject[:status]).to eq(:success)

          expect(build.job_annotations).to be_empty
        end
      end

      context 'when artifact has the specified blob' do
        let(:blob) { data.to_json }

        before do
          allow(artifact).to receive(:each_blob).and_yield(blob)
        end

        context 'when valid annotations are given' do
          let(:data) do
            {
              external_links: [
                {
                  external_link: {
                    label: 'URL 1',
                    url: 'https://url1.example.com/'
                  }
                },
                {
                  external_link: {
                    label: 'URL 2',
                    url: 'https://url2.example.com/'
                  }
                }
              ]
            }
          end

          it 'parses the artifact' do
            subject

            expect(build.job_annotations.as_json).to contain_exactly(
              hash_including('name' => 'external_links', 'data' => [
                hash_including('external_link' => hash_including('label' => 'URL 1', 'url' => 'https://url1.example.com/')),
                hash_including('external_link' => hash_including('label' => 'URL 2', 'url' => 'https://url2.example.com/'))
              ])
            )
          end
        end

        context 'when valid annotations are given and annotation list name is the same' do
          before do
            build.job_annotations.create!(name: 'external_links', data: [
              {
                external_link: {
                  label: 'URL 1',
                  url: 'https://url1.example.com/'
                }
              }
            ])
          end

          let(:data) do
            {
              external_links: [
                {
                  external_link: {
                    label: 'URL 2',
                    url: 'https://url2.example.com/'
                  }
                }
              ]
            }
          end

          it 'parses the artifact' do
            subject

            expect(build.job_annotations.as_json).to contain_exactly(
              hash_including('name' => 'external_links', 'data' => [
                hash_including('external_link' => hash_including('label' => 'URL 2', 'url' => 'https://url2.example.com/'))
              ])
            )
          end
        end

        context 'when invalid JSON is given' do
          let(:blob) { 'Invalid JSON!' }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when root is not an object' do
          let(:data) { [] }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Annotations files must be a JSON object')
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when item is not a valid annotation list' do
          let(:data) { { external_links: {} } }

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq('Validation failed: Data must be a valid json schema')
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end

        context 'when more than limitated annotations are specified in annotations' do
          let(:data) do
            {
              external_links_1: [
                {
                  external_link: {
                    label: 'URL',
                    url: 'https://example.com/'
                  }
                }
              ],
              external_links_2: [
                {
                  external_link: {
                    label: 'URL',
                    url: 'https://example.com/'
                  }
                }
              ]
            }
          end

          before do
            allow(service).to receive(:annotations_num_limit).and_return(1)
          end

          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to eq(
              "Annotations files cannot have more than #{service.send(:annotations_num_limit)} annotation lists")
            expect(subject[:http_status]).to eq(:bad_request)
          end
        end
      end

      context 'when artifact size is too big' do
        before do
          allow(artifact.file).to receive(:size) { service.send(:annotations_size_limit) + 1.kilobyte }
        end

        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq(
            "Annotations Artifact Too Big. Maximum Allowable Size: #{service.send(:annotations_size_limit)}")
          expect(subject[:http_status]).to eq(:bad_request)
        end
      end
    end
  end
end
