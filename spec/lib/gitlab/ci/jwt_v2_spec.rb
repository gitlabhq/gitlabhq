# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2, feature_category: :continuous_integration do
  let(:namespace) { build_stubbed(:namespace) }
  let(:project) { build_stubbed(:project, namespace: namespace) }
  let(:user) do
    build_stubbed(
      :user,
      identities: [build_stubbed(:identity, extern_uid: '1', provider: 'github')]
    )
  end

  let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'auto-deploy-2020-03-19') }
  let(:runner) { build_stubbed(:ci_runner) }
  let(:aud) { described_class::DEFAULT_AUD }

  let(:build) do
    build_stubbed(
      :ci_build,
      project: project,
      user: user,
      pipeline: pipeline,
      runner: runner
    )
  end

  subject(:ci_job_jwt_v2) { described_class.new(build, ttl: 30, aud: aud) }

  it { is_expected.to be_a Gitlab::Ci::Jwt }

  describe '#payload' do
    subject(:payload) { ci_job_jwt_v2.payload }

    it 'has correct values for the standard JWT attributes' do
      aggregate_failures do
        expect(payload[:iss]).to eq(Settings.gitlab.base_url)
        expect(payload[:aud]).to eq(Settings.gitlab.base_url)
        expect(payload[:sub]).to eq("project_path:#{project.full_path}:ref_type:branch:ref:#{pipeline.source_ref}")
      end
    end

    it 'includes user identities when enabled' do
      expect(user).to receive(:pass_user_identities_to_ci_jwt).and_return(true)
      identities = payload[:user_identities].map { |identity| identity.slice(:extern_uid, :provider) }
      expect(identities).to eq([{ extern_uid: '1', provider: 'github' }])
    end

    it 'does not include user identities when disabled' do
      expect(user).to receive(:pass_user_identities_to_ci_jwt).and_return(false)

      expect(payload).not_to include(:user_identities)
    end

    context 'when given an aud' do
      let(:aud) { 'AWS' }

      it 'uses that aud in the payload' do
        expect(payload[:aud]).to eq('AWS')
      end
    end

    describe 'custom claims' do
      describe 'runner_id' do
        it 'is the ID of the runner executing the job' do
          expect(payload[:runner_id]).to eq(runner.id)
        end

        context 'when build is not associated with a runner' do
          let(:runner) { nil }

          it 'is nil' do
            expect(payload[:runner_id]).to be_nil
          end
        end
      end

      describe 'runner_environment' do
        context 'when runner is gitlab-hosted' do
          before do
            allow(runner).to receive(:gitlab_hosted?).and_return(true)
          end

          it "is #{described_class::GITLAB_HOSTED_RUNNER}" do
            expect(payload[:runner_environment]).to eq(described_class::GITLAB_HOSTED_RUNNER)
          end
        end

        context 'when runner is self-hosted' do
          before do
            allow(runner).to receive(:gitlab_hosted?).and_return(false)
          end

          it "is #{described_class::SELF_HOSTED_RUNNER}" do
            expect(payload[:runner_environment]).to eq(described_class::SELF_HOSTED_RUNNER)
          end
        end

        context 'when build is not associated with a runner' do
          let(:runner) { nil }

          it 'is nil' do
            expect(payload[:runner_environment]).to be_nil
          end
        end
      end

      describe 'sha' do
        it 'is the commit revision the project is built for' do
          expect(payload[:sha]).to eq(pipeline.sha)
        end
      end

      describe 'pipeline_ref' do
        let(:project_config) { instance_double(Gitlab::Ci::ProjectConfig, url: url) }
        let(:url) { 'https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml' }

        before do
          allow(Gitlab::Ci::ProjectConfig).to receive(:new).with(
            project: project,
            sha: pipeline.sha,
            pipeline_source: pipeline.source.to_sym,
            pipeline_source_bridge: pipeline.source_bridge,
            pipeline: build.pipeline
          ).and_return(project_config)
        end

        it 'delegates to ProjectConfig#url' do
          expect(payload[:pipeline_ref]).to eq(url)
        end

        context 'when project config is nil' do
          before do
            allow(Gitlab::Ci::ProjectConfig).to receive(:new).and_return(nil)
          end

          it 'is nil' do
            expect(payload[:pipeline_ref]).to be_nil
          end
        end

        context 'when ProjectConfig#url raises an error' do
          before do
            allow_next_instance_of(Gitlab::Ci::ProjectConfig) do |instance|
              allow(instance).to receive(:url).and_raise(RuntimeError)
            end
          end

          it 'raises the same error' do
            expect { payload }.to raise_error(RuntimeError)
          end

          context 'in production' do
            before do
              stub_rails_env('production')
            end

            it 'is nil' do
              expect(payload[:pipeline_ref]).to be_nil
            end
          end
        end
      end

      describe 'pipeline_sha' do
        context 'when pipeline config_source is repository' do
          before do
            pipeline.config_source = Enums::Ci::Pipeline.config_sources[:repository_source]
          end

          it 'is the pipeline\'s sha' do
            expect(payload[:pipeline_sha]).to eq(pipeline.sha)
          end
        end

        context 'when pipeline config_source is not repository' do
          before do
            pipeline.config_source = Enums::Ci::Pipeline.config_sources[:unknown_source]
          end

          it 'is nil' do
            expect(payload[:pipeline_sha]).to eq(nil)
          end
        end
      end
    end
  end
end
