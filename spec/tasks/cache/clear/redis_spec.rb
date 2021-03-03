# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'clearing redis cache', :clean_gitlab_redis_cache do
  before do
    Rake.application.rake_require 'tasks/cache'
  end

  describe 'clearing pipeline status cache' do
    let(:pipeline_status) do
      project = create(:project, :repository)
      create(:ci_pipeline, project: project).project.pipeline_status
    end

    before do
      allow(pipeline_status).to receive(:loaded).and_return(nil)
    end

    it 'clears pipeline status cache' do
      expect { run_rake_task('cache:clear:redis') }.to change { pipeline_status.has_cache? }
    end
  end

  describe 'invoking clear description templates cache rake task' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_env('project_ids', project_ids) if project_ids
      service = double(:service, execute: true)

      expect(Gitlab::Cleanup::Redis::DescriptionTemplatesCacheKeysPatternBuilder).to receive(:new).with(expected_project_ids).and_return(service)
      expect(Gitlab::Cleanup::Redis::BatchDeleteByPattern).to receive(:new).and_return(service)
    end

    where(:project_ids, :expected_project_ids) do
      nil                    | [] # this acts as no argument is being passed
      '1'                    | %w[1]
      '1, 2, 3'              | %w[1 2 3]
      '1, 2, some-string, 3' | %w[1 2 some-string 3]
    end

    with_them do
      specify { run_rake_task('cache:clear:description_templates') }
    end
  end
end
