# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2, feature_category: :secrets_management do
  include ProjectForksHelper

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
  let(:aud) { nil }
  let(:sub_components) { [:project_path, :ref_type, :ref] }
  let(:target_audience) { nil }

  let(:build) do
    build_stubbed(
      :ci_build,
      project: project,
      user: user,
      pipeline: pipeline,
      runner: runner
    )
  end

  subject(:ci_job_jwt_v2) do
    described_class.new(build, ttl: 30, aud: aud, sub_components: sub_components,
      target_audience: target_audience)
  end

  it { is_expected.to be_a Gitlab::Ci::Jwt }

  describe '#payload' do
    subject(:payload) { ci_job_jwt_v2.payload }

    it 'includes user identities when enabled' do
      expect(user).to receive(:pass_user_identities_to_ci_jwt).and_return(true)
      identities = payload[:user_identities].map { |identity| identity.slice(:extern_uid, :provider) }
      expect(identities).to eq([{ extern_uid: '1', provider: 'github' }])
    end

    it 'does not include user identities when disabled' do
      expect(user).to receive(:pass_user_identities_to_ci_jwt).and_return(false)

      expect(payload).not_to include(:user_identities)
    end

    it 'has correct values for the standard JWT attributes' do
      aggregate_failures do
        expect(payload[:iss]).to eq(Gitlab.config.gitlab.url)
        expect(payload[:sub]).to eq("project_path:#{project.full_path}:ref_type:branch:ref:#{pipeline.source_ref}")
      end
    end

    describe 'when only project_path provided' do
      let(:sub_components) { [:project_path] }

      it 'has only project_path in sub section' do
        aggregate_failures do
          expect(payload[:sub]).to eq("project_path:#{project.full_path}")
        end
      end
    end

    describe 'when project_path and ref_type provided' do
      let(:sub_components) { [:project_path, :ref_type] }

      it 'has project_path and ref_type in sub section' do
        aggregate_failures do
          expect(payload[:sub]).to eq("project_path:#{project.full_path}:ref_type:branch")
        end
      end
    end

    describe 'when project_path and ref provided' do
      let(:sub_components) { [:project_path, :ref] }

      it 'has project_path and ref_type in sub section' do
        aggregate_failures do
          expect(payload[:sub]).to eq("project_path:#{project.full_path}:ref:#{pipeline.source_ref}")
        end
      end
    end

    describe 'when project_path and invalid claim provided' do
      let(:sub_components) { [:project_path, :not_existing_claim] }

      it 'has project_path' do
        aggregate_failures do
          expect(payload[:sub]).to eq("project_path:#{project.full_path}")
        end
      end
    end

    context 'when given an aud' do
      let(:aud) { 'AWS' }

      it 'uses that aud in the payload' do
        expect(payload[:aud]).to eq('AWS')
      end

      it 'does not use target_audience claim in the payload' do
        expect(payload.include?(:target_audience)).to be_falsey
      end
    end

    context 'when given an target_audience claim' do
      let(:target_audience) { '//iam.googleapis.com/foo' }

      it 'uses specified target_audience in the payload' do
        expect(payload[:target_audience]).to eq(target_audience)
      end
    end

    describe 'custom claims' do
      let(:project_config) do
        instance_double(
          Gitlab::Ci::ProjectConfig,
          url: 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml',
          source: :repository_source
        )
      end

      before do
        allow(Gitlab::Ci::ProjectConfig).to receive(:new).with(
          project: project,
          sha: pipeline.sha,
          pipeline_source: pipeline.source.to_sym,
          pipeline_source_bridge: pipeline.source_bridge
        ).and_return(project_config)
      end

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
            allow(runner).to receive(:dot_com_gitlab_hosted?).and_return(true)
          end

          it "is #{described_class::GITLAB_HOSTED_RUNNER}" do
            expect(payload[:runner_environment]).to eq(described_class::GITLAB_HOSTED_RUNNER)
          end
        end

        context 'when runner is self-hosted' do
          before do
            allow(runner).to receive(:dot_com_gitlab_hosted?).and_return(false)
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

      describe 'claims delegated to mapper' do
        let(:ci_config_ref_uri) { 'ci_config_ref_uri' }
        let(:ci_config_sha) { 'ci_config_sha' }

        it 'delegates claims to Gitlab::Ci::JwtV2::ClaimMapper' do
          expect_next_instance_of(Gitlab::Ci::JwtV2::ClaimMapper, project_config, pipeline) do |mapper|
            expect(mapper).to receive(:to_h).and_return({
              ci_config_ref_uri: ci_config_ref_uri,
              ci_config_sha: ci_config_sha
            })
          end

          expect(payload[:ci_config_ref_uri]).to eq(ci_config_ref_uri)
          expect(payload[:ci_config_sha]).to eq(ci_config_sha)
        end
      end

      describe 'project_visibility' do
        using RSpec::Parameterized::TableSyntax

        where(:visibility_level, :visibility_level_string) do
          Project::PUBLIC   | 'public'
          Project::INTERNAL | 'internal'
          Project::PRIVATE  | 'private'
        end

        with_them do
          before do
            project.visibility_level = visibility_level
          end

          it 'is a string representation of the project visibility_level' do
            expect(payload[:project_visibility]).to eq(visibility_level_string)
          end
        end
      end
    end

    describe 'custom issuer url' do
      let(:custom_issuer_url) { 'https://example-oidc-configuration-bucket.s3.eu-north-1.amazonaws.com/' }

      before do
        allow(Gitlab.config.ci_id_tokens).to receive(:issuer_url).and_return(custom_issuer_url)
      end

      it 'uses the custom issuer url for the iss: claim' do
        expect(payload[:iss]).to eq(custom_issuer_url)
      end
    end

    context 'when the pipeline is for a merge request from a forked project' do
      let_it_be(:target_project_namespace) { create(:namespace) }
      let_it_be(:target_project) { create(:project, namespace: target_project_namespace) }
      let_it_be(:forked_project_namespace) { create(:namespace) }
      let_it_be(:forked_project) do
        fork_project(target_project, nil, repository: true, namespace: forked_project_namespace)
      end

      let(:merge_request) do
        build_stubbed(:merge_request, source_project: forked_project, source_branch: 'feature',
          target_project: target_project, target_branch: 'master')
      end

      let(:pipeline) do
        build_stubbed(:ci_pipeline, source: :merge_request_event, merge_request: merge_request,
          project: target_project, user: user)
      end

      let(:build) do
        build_stubbed(
          :ci_build,
          project: target_project,
          user: user,
          pipeline: pipeline
        )
      end

      it 'sets the project related claims based on the source project of the merge request' do
        expect(payload[:project_id]).to eq(forked_project.id.to_s)
        expect(payload[:project_path]).to eq(forked_project.full_path)
        expect(payload[:namespace_id]).to eq(forked_project_namespace.id.to_s)
        expect(payload[:namespace_path]).to eq(forked_project_namespace.full_path)
      end

      it 'sets the job project related claims of the merge request' do
        expect(payload[:job_project_id]).to eq(target_project.id.to_s)
        expect(payload[:job_project_path]).to eq(target_project.full_path)
        expect(payload[:job_namespace_id]).to eq(target_project_namespace.id.to_s)
        expect(payload[:job_namespace_path]).to eq(target_project_namespace.full_path)
      end

      it 'sets the job project related claims different to the source project claims' do
        expect(payload[:job_project_id]).not_to eq(payload[:project_id])
        expect(payload[:job_project_path]).not_to eq(payload[:project_path])
        expect(payload[:job_namespace_id]).not_to eq(payload[:namespace_id])
        expect(payload[:job_namespace_path]).not_to eq(payload[:namespace_path])
      end

      it 'in the sub: claim, it sets the project path component based on the source project of the merge request' do
        expect(payload[:project_id]).to eq(forked_project.id.to_s)
        expect(payload[:sub])
        .to eq("project_path:#{forked_project.full_path}:ref_type:branch:ref:#{pipeline.source_ref}")
        expect(payload[:sub])
        .not_to eq("project_path:#{target_project.full_path}:ref_type:branch:ref:#{pipeline.source_ref}")
      end

      describe 'claims delegated to mapper' do
        where(:source) do
          [
            :repository_source,
            :bridge_source
          ]
        end

        with_them do
          let(:project_config) do
            instance_double(
              Gitlab::Ci::ProjectConfig,
              url: 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml',
              source: source
            )
          end

          it 'delegates claims to Gitlab::Ci::JwtV2::ClaimMapper' do
            expect(Gitlab::Ci::ProjectConfig).to receive(:new).with(
              project: target_project,
              sha: pipeline.sha,
              pipeline_source: pipeline.source.to_sym,
              pipeline_source_bridge: pipeline.source_bridge
            ).and_return(project_config)

            expect(payload[:project_id]).to eq(forked_project.id.to_s)
            expect(payload[:ci_config_ref_uri]).to eq("#{project_config.url}@#{pipeline.source_ref_path}")
            expect(payload[:ci_config_sha]).to eq(pipeline.sha)
          end
        end
      end

      context "when FF is disabled and bridge source" do
        before do
          stub_feature_flags(sigstore_child_pipelines_fix: false)
        end

        let(:project_config) do
          instance_double(
            Gitlab::Ci::ProjectConfig,
            url: 'gitlab.com/gitlab-org/gitlab//.gitlab-ci.yml',
            source: :bridge_source
          )
        end

        it 'preserves original behaviour' do
          expect(Gitlab::Ci::ProjectConfig).to receive(:new).with(
            project: target_project,
            sha: pipeline.sha,
            pipeline_source: pipeline.source.to_sym,
            pipeline_source_bridge: pipeline.source_bridge
          ).and_return(project_config)

          expect(payload[:ci_config_ref_uri]).to be_nil
          expect(payload[:ci_config_sha]).to be_nil
        end
      end
    end
  end
end
