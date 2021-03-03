# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::Redis::DescriptionTemplatesCacheKeysPatternBuilder, :clean_gitlab_redis_cache do
  subject { described_class.new(project_ids).execute }

  describe 'execute' do
    context 'when build pattern for all description templates' do
      RSpec.shared_examples 'all issue and merge request templates pattern' do
        it 'builds pattern to remove all issue and merge request templates keys' do
          expect(subject.count).to eq(2)
          expect(subject).to match_array(%W[
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:issue_template_names_hash:*
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:merge_request_template_names_hash:*
          ])
        end
      end

      context 'with project_ids == :all' do
        let(:project_ids) { :all }

        it_behaves_like 'all issue and merge request templates pattern'
      end
    end

    context 'with project_ids' do
      let_it_be(:project1) { create(:project, :repository) }
      let_it_be(:project2) { create(:project, :repository) }

      context 'with nil project_ids' do
        let(:project_ids) { nil }

        specify { expect { subject }.to raise_error(ArgumentError, 'project_ids can either be an array of project IDs or :all') }
      end

      context 'with project_ids as string' do
        let(:project_ids) { '1' }

        specify { expect { subject }.to raise_error(ArgumentError, 'project_ids can either be an array of project IDs or :all') }
      end

      context 'with invalid project_ids as array of strings' do
        let(:project_ids) { %w[a b] }

        specify { expect { subject }.to raise_error(ArgumentError, 'Invalid Project ID. Please ensure all passed in project ids values are valid integer project ids.') }
      end

      context 'with non existent project id' do
        let(:project_ids) { [non_existing_record_id] }

        it 'no patterns are built' do
          expect(subject.count).to eq(0)
        end
      end

      context 'with one project_id' do
        let(:project_ids) { [project1.id] }

        it 'builds patterns for the project' do
          expect(subject.count).to eq(2)
          expect(subject).to match_array(%W[
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:issue_template_names_hash:#{project1.full_path}:#{project1.id}
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:merge_request_template_names_hash:#{project1.full_path}:#{project1.id}
          ])
        end
      end

      context 'with many project_ids' do
        let(:project_ids) { [project1.id, project2.id] }

        RSpec.shared_examples 'builds patterns for the given projects' do
          it 'builds patterns for the given projects' do
            expect(subject.count).to eq(4)
            expect(subject).to match_array(%W[
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:issue_template_names_hash:#{project1.full_path}:#{project1.id}
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:merge_request_template_names_hash:#{project1.full_path}:#{project1.id}
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:issue_template_names_hash:#{project2.full_path}:#{project2.id}
            #{Gitlab::Redis::Cache::CACHE_NAMESPACE}:merge_request_template_names_hash:#{project2.full_path}:#{project2.id}
            ])
          end
        end

        it_behaves_like 'builds patterns for the given projects'

        context 'with project_ids as string' do
          let(:project_ids) { [project1.id.to_s, project2.id.to_s] }

          it_behaves_like 'builds patterns for the given projects'
        end
      end
    end
  end
end
