# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Tags::Resolver, feature_category: :pipeline_composition do
  let(:config) do
    Gitlab::Ci::Config::Yaml::Loader.new(yaml).load.content
  end

  describe '#to_hash' do
    subject { described_class.new(config).to_hash }

    context 'when referencing deeply nested arrays' do
      let(:yaml_templates) do
        <<~YML
        .job-1:
          script:
            - echo doing step 1 of job 1
            - echo doing step 2 of job 1

        .job-2:
          script:
            - echo doing step 1 of job 2
            - !reference [.job-1, script]
            - echo doing step 2 of job 2

        .job-3:
          script:
            - echo doing step 1 of job 3
            - !reference [.job-2, script]
            - echo doing step 2 of job 3
        YML
      end

      let(:job_yaml) do
        <<~YML
        test:
          script:
            - echo preparing to test
            - !reference [.job-3, script]
            - echo test finished
        YML
      end

      shared_examples 'expands references' do
        it 'expands the references' do
          is_expected.to match({
            '.job-1': {
              script: [
                'echo doing step 1 of job 1',
                'echo doing step 2 of job 1'
              ]
            },
            '.job-2': {
              script: [
                'echo doing step 1 of job 2',
                [
                  'echo doing step 1 of job 1',
                  'echo doing step 2 of job 1'
                ],
                'echo doing step 2 of job 2'
              ]
            },
            '.job-3': {
              script: [
                'echo doing step 1 of job 3',
                [
                  'echo doing step 1 of job 2',
                  [
                    'echo doing step 1 of job 1',
                    'echo doing step 2 of job 1'
                  ],
                  'echo doing step 2 of job 2'
                ],
                'echo doing step 2 of job 3'
              ]
            },
            test: {
              script: [
                'echo preparing to test',
                [
                  'echo doing step 1 of job 3',
                  [
                    'echo doing step 1 of job 2',
                    [
                      'echo doing step 1 of job 1',
                      'echo doing step 2 of job 1'
                    ],
                    'echo doing step 2 of job 2'
                  ],
                  'echo doing step 2 of job 3'
                ],
                'echo test finished'
              ]
            }
          })
        end
      end

      context 'when templates are defined before the job' do
        let(:yaml) do
          <<~YML
          #{yaml_templates}
          #{job_yaml}
          YML
        end

        it_behaves_like 'expands references'
      end

      context 'when templates are defined after the job' do
        let(:yaml) do
          <<~YML
          #{job_yaml}
          #{yaml_templates}
          YML
        end

        it_behaves_like 'expands references'
      end
    end
  end
end
