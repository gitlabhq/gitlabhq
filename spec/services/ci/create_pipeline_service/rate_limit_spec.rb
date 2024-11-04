# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :freeze_time,
  :clean_gitlab_redis_rate_limiting,
  feature_category: :continuous_integration do
  describe 'rate limiting' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    let(:ref) { 'refs/heads/master' }

    before do
      stub_ci_pipeline_yaml_file(gitlab_ci_yaml)
      stub_application_setting(pipeline_limit_per_project_user_sha: 1)
      stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: false)
    end

    context 'when user is under the limit' do
      let(:pipeline) { create_pipelines(count: 1) }

      it 'allows pipeline creation' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.statuses).not_to be_empty
      end
    end

    context 'when user is over the limit' do
      let(:pipeline) { create_pipelines }

      it 'blocks pipeline creation' do
        throttle_message = 'Too many pipelines created in the last minute. Try again later.'

        expect(pipeline).not_to be_persisted
        expect(pipeline.statuses).to be_empty
        expect(pipeline.errors.added?(:base, throttle_message)).to be_truthy
      end
    end

    context 'with different users' do
      let(:other_user) { create(:user) }

      before do
        project.add_maintainer(other_user)
      end

      it 'allows other members to create pipelines' do
        blocked_pipeline = create_pipelines(user: user)
        allowed_pipeline = create_pipelines(count: 1, user: other_user)

        expect(blocked_pipeline).not_to be_persisted
        expect(allowed_pipeline).to be_created_successfully
      end
    end

    context 'with different commits' do
      it 'allows user to create pipeline' do
        blocked_pipeline = create_pipelines(ref: ref)
        allowed_pipeline = create_pipelines(count: 1, ref: 'refs/heads/feature')

        expect(blocked_pipeline).not_to be_persisted
        expect(allowed_pipeline).to be_created_successfully
      end
    end

    context 'with different projects' do
      let_it_be(:other_project) { create(:project, :repository) }

      before do
        other_project.add_maintainer(user)
      end

      it 'allows user to create pipeline' do
        blocked_pipeline = create_pipelines(project: project)
        allowed_pipeline = create_pipelines(count: 1, project: other_project)

        expect(blocked_pipeline).not_to be_persisted
        expect(allowed_pipeline).to be_created_successfully
      end
    end
  end

  def create_pipelines(attrs = {})
    attrs.reverse_merge!(user: user, ref: ref, project: project, count: 2)

    service = described_class.new(attrs[:project], attrs[:user], { ref: attrs[:ref] })

    attrs[:count].pred.times { service.execute(:push) }
    service.execute(:push).payload
  end
end
