# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'google cloud profiler', :aggregate_failures, feature_category: :cloud_connector do
  subject(:load_initializer) do
    load rails_root_join('config/initializers/google_cloud_profiler.rb')
  end

  shared_examples 'does not call profiler agent' do
    it do
      expect(CloudProfilerAgent::Agent).not_to receive(:new)

      load_initializer
    end
  end

  context 'when GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED is set to true' do
    before do
      stub_env('GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED', true)
    end

    context 'when GITLAB_GOOGLE_CLOUD_PROFILER_PROJECT_ID is not set' do
      include_examples 'does not call profiler agent'
    end

    context 'when GITLAB_GOOGLE_CLOUD_PROFILER_PROJECT_ID is set' do
      let(:project_id) { 'gitlab-staging-1' }
      let(:agent) { instance_double(CloudProfilerAgent::Agent) }

      before do
        stub_env('GITLAB_GOOGLE_CLOUD_PROFILER_PROJECT_ID', project_id)
      end

      context 'when run in Puma context' do
        before do
          allow(::Gitlab::Runtime).to receive(:puma?).and_return(true)
          allow(::Gitlab::Runtime).to receive(:sidekiq?).and_return(false)
        end

        it 'calls the agent' do
          expect(CloudProfilerAgent::Agent)
            .to receive(:new).with(service: 'gitlab-web', project_id: project_id,
              logger: an_instance_of(::Gitlab::AppJsonLogger),
              log_labels: hash_including(
                message: 'Google Cloud Profiler Ruby',
                pid: be_a(Integer),
                worker_id: be_a(String)
              )).and_return(agent)
          expect(agent).to receive(:start)

          load_initializer
        end
      end

      context 'when run in Sidekiq context' do
        before do
          allow(::Gitlab::Runtime).to receive(:puma?).and_return(false)
          allow(::Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        end

        include_examples 'does not call profiler agent'
      end

      context 'when run in another context' do
        before do
          allow(::Gitlab::Runtime).to receive(:puma?).and_return(false)
          allow(::Gitlab::Runtime).to receive(:sidekiq?).and_return(false)
        end

        include_examples 'does not call profiler agent'
      end
    end
  end

  context 'when GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED is not set' do
    include_examples 'does not call profiler agent'
  end

  context 'when GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED is set to false' do
    before do
      stub_env('GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED', false)
    end

    include_examples 'does not call profiler agent'
  end
end
