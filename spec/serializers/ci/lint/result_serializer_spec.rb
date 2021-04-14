# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Lint::ResultSerializer, :aggregate_failures do
  let_it_be(:project) { create(:project, :repository) }

  let(:result) do
    Gitlab::Ci::Lint
      .new(project: project, current_user: project.owner)
      .validate(yaml_content, dry_run: false)
  end

  let(:first_job) { linting_result[:jobs].first }
  let(:serialized_linting_result) { linting_result.to_json }

  subject(:linting_result) { described_class.new.represent(result) }

  shared_examples 'matches schema' do
    it { expect(serialized_linting_result).to match_schema('entities/lint_result_entity') }
  end

  context 'when config is invalid' do
    let(:yaml_content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }

    it_behaves_like 'matches schema'

    it 'returns expected validity' do
      expect(linting_result[:valid]).to eq(false)
      expect(linting_result[:errors]).to eq(['jobs:rspec:tags config should be an array of strings'])
      expect(linting_result[:warnings]).to eq([])
    end

    it 'returns job data' do
      expect(linting_result[:jobs]).to eq([])
    end
  end

  context 'when config is valid' do
    let(:yaml_content) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

    it_behaves_like 'matches schema'

    it 'returns expected validity' do
      expect(linting_result[:valid]).to eq(true)
      expect(linting_result[:errors]).to eq([])
      expect(linting_result[:warnings]).to eq([])
    end

    it 'returns job data' do
      expect(first_job[:name]).to eq('rspec')
      expect(first_job[:stage]).to eq('test')
      expect(first_job[:before_script]).to eq(['bundle install', 'bundle exec rake db:create'])
      expect(first_job[:script]).to eq(['rake spec'])
      expect(first_job[:after_script]).to eq([])
      expect(first_job[:tag_list]).to eq(%w[ruby postgres])
      expect(first_job[:environment]).to eq(nil)
      expect(first_job[:when]).to eq('on_success')
      expect(first_job[:allow_failure]).to eq(false)
      expect(first_job[:only]).to eq(refs: ['branches'])
      expect(first_job[:except]).to eq(nil)
    end

    context 'when dry run is enabled' do
      let(:result) do
        Gitlab::Ci::Lint
          .new(project: project, current_user: project.owner)
          .validate(yaml_content, dry_run: true)
      end

      it_behaves_like 'matches schema'

      it 'returns expected validity' do
        expect(linting_result[:valid]).to eq(true)
        expect(linting_result[:errors]).to eq([])
        expect(linting_result[:warnings]).to eq([])
      end

      it 'returns job data' do
        expect(first_job[:name]).to eq('rspec')
        expect(first_job[:stage]).to eq('test')
        expect(first_job[:before_script]).to eq(['bundle install', 'bundle exec rake db:create'])
        expect(first_job[:script]).to eq(['rake spec'])
        expect(first_job[:after_script]).to eq([])
        expect(first_job[:tag_list]).to eq(%w[ruby postgres])
        expect(first_job[:environment]).to eq(nil)
        expect(first_job[:when]).to eq('on_success')
        expect(first_job[:allow_failure]).to eq(false)
        expect(first_job[:only]).to eq(nil)
        expect(first_job[:except]).to eq(nil)
      end
    end

    context 'when only is not nil in the yaml' do
      context 'when only: is hash' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              script: echo
              only:
                refs:
                  - branches
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders only:refs as hash' do
          expect(first_job[:only]).to eq(refs: ['branches'])
        end
      end

      context 'when only is an array of strings in the yaml' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              script: echo
              only:
                - pushes
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders only: list as hash' do
          expect(first_job[:only]).to eq(refs: ['pushes'])
        end
      end
    end

    context 'when except is not nil in the yaml' do
      context 'when except: is hash' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              script: echo
              except:
                refs:
                  - branches
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders except as hash' do
          expect(first_job[:except]).to eq(refs: ['branches'])
        end
      end

      context 'when except is an array of strings in the yaml' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              script: echo
              except:
                - pushes
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders only: list as hash' do
          expect(first_job[:except]).to eq(refs: ['pushes'])
        end
      end

      context 'with minimal job configuration' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              script: echo
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders the job with defaults' do
          expect(first_job[:name]).to eq('build')
          expect(first_job[:stage]).to eq('build')
          expect(first_job[:before_script]).to eq([])
          expect(first_job[:script]).to eq(['echo'])
          expect(first_job[:after_script]).to eq([])
          expect(first_job[:tag_list]).to eq([])
          expect(first_job[:environment]).to eq(nil)
          expect(first_job[:when]).to eq('on_success')
          expect(first_job[:allow_failure]).to eq(false)
          expect(first_job[:only]).to eq(refs: %w[branches tags])
          expect(first_job[:except]).to eq(nil)
        end
      end

      context 'with environment defined' do
        context 'when formatted as a hash in yaml' do
          let(:yaml_content) do
            <<~YAML
              build:
                stage: build
                script: echo
                environment:
                  name: production
                  url: https://example.com
            YAML
          end

          it_behaves_like 'matches schema'

          it 'renders the environment as a string' do
            expect(first_job[:environment]).to eq('production')
          end
        end

        context 'when formatted as a string in yaml' do
          let(:yaml_content) do
            <<~YAML
              build:
                stage: build
                script: echo
                environment: production
            YAML
          end

          it_behaves_like 'matches schema'

          it 'renders the environment as a string' do
            expect(first_job[:environment]).to eq('production')
          end
        end
      end

      context 'when script values are formatted as arrays in the yaml' do
        let(:yaml_content) do
          <<~YAML
            build:
              stage: build
              before_script:
                - echo
                - cat '~/.zshrc'
              script:
                - echo
                - cat '~/.zshrc'
              after_script:
                - echo
                - cat '~/.zshrc'
          YAML
        end

        it_behaves_like 'matches schema'

        it 'renders the scripts as arrays' do
          expect(first_job[:before_script]).to eq(['echo', "cat '~/.zshrc'"])
          expect(first_job[:script]).to eq(['echo', "cat '~/.zshrc'"])
          expect(first_job[:after_script]).to eq(['echo', "cat '~/.zshrc'"])
        end
      end
    end
  end
end
