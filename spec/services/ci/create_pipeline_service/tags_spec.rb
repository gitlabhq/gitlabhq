# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :continuous_integration do
  describe 'tags:' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    let(:ref) { 'refs/heads/master' }
    let(:service) { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { create_pipeline }

    before do
      stub_yaml_config(config)
    end

    context 'with valid config' do
      let(:config) { { test: { script: 'ls', tags: %w[tag1 tag2] } } }

      it 'creates a pipeline', :aggregate_failures do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.first.tag_list).to match_array(%w[tag1 tag2])
      end
    end

    context 'with too many tags' do
      let(:tags) { build_tag_list(label: 'custom', size: 50) }
      let(:config) { { test: { script: 'ls', tags: tags } } }

      it 'creates a pipeline without builds', :aggregate_failures do
        expect(pipeline).not_to be_created_successfully
        expect(pipeline.builds).to be_empty
        expect(pipeline.yaml_errors).to eq("jobs:test:tags config must be less than the limit of #{Gitlab::Ci::Config::Entry::Tags::TAGS_LIMIT} tags")
      end
    end

    context 'tags persistence' do
      let(:config) do
        {
          build: {
            script: 'ls',
            stage: 'build',
            tags: build_tag_list(label: 'build')
          },
          test: {
            script: 'ls',
            stage: 'test',
            tags: build_tag_list(label: 'test')
          }
        }
      end

      let(:config_without_tags) do
        config.transform_values { |job| job.except(:tags) }
      end

      context 'with multiple tags' do
        context 'when the tags do not exist' do
          it 'does not execute N+1 queries' do
            stub_yaml_config(config_without_tags)

            # warm up the cached objects so we get a more accurate count
            create_pipeline

            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              create_pipeline
            end

            stub_yaml_config(config)

            # 2 select tags.*
            # 1 insert tags
            # 1 insert taggings
            tags_queries_size = 4

            expect { pipeline }
              .not_to exceed_all_query_limit(control)
              .with_threshold(tags_queries_size)

            expect(pipeline).to be_created_successfully
          end
        end

        context 'when tags are already persisted' do
          it 'does not execute N+1 queries' do
            # warm up the cached objects so we get a more accurate count
            # and insert the tags
            create_pipeline

            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              create_pipeline
            end

            # 1 select tags.*
            # 1 insert taggings
            tags_queries_size = 2

            expect { pipeline }
              .not_to exceed_all_query_limit(control)
              .with_threshold(tags_queries_size)

            expect(pipeline).to be_created_successfully
          end
        end
      end

      context 'with bridge jobs' do
        let(:config) do
          {
            test_1: {
              script: 'ls',
              stage: 'test',
              tags: build_tag_list(label: 'test_1')
            },
            test_2: {
              script: 'ls',
              stage: 'test',
              tags: build_tag_list(label: '$CI_JOB_NAME')
            },
            test_3: {
              script: 'ls',
              stage: 'test',
              tags: build_tag_list(label: 'test_1') + build_tag_list(label: 'test_2')
            },
            test_4: {
              script: 'ls',
              stage: 'test'
            },
            deploy: {
              stage: 'deploy',
              trigger: 'my/project'
            }
          }
        end

        it do
          expect(pipeline).to be_created_successfully
          expect(pipeline.bridges.size).to eq(1)
          expect(pipeline.builds.size).to eq(4)

          expect(tags_for('test_1'))
            .to have_attributes(count: 5)
            .and all(match(/test_1-tag-\d+/))

          expect(tags_for('test_2'))
            .to have_attributes(count: 5)
            .and all(match(/test_2-tag-\d+/))

          expect(tags_for('test_3'))
            .to have_attributes(count: 10)
            .and all(match(/test_[1,2]-tag-\d+/))

          expect(tags_for('test_4')).to be_empty
        end
      end
    end
  end

  def tags_for(build_name)
    pipeline.builds.find_by_name(build_name).tag_list
  end

  def stub_yaml_config(config)
    stub_ci_pipeline_yaml_file(YAML.dump(config))
  end

  def create_pipeline
    service.execute(:push).payload
  end

  def build_tag_list(label:, size: 5)
    Array.new(size) { |index| "#{label}-tag-#{index}" }
  end
end
