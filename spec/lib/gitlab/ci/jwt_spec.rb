# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Jwt do
  let(:namespace) { build_stubbed(:namespace) }
  let(:project) { build_stubbed(:project, namespace: namespace) }
  let(:user) { build_stubbed(:user) }
  let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'auto-deploy-2020-03-19') }
  let(:build) do
    build_stubbed(
      :ci_build,
      project: project,
      user: user,
      pipeline: pipeline
    )
  end

  describe '#payload' do
    subject(:payload) { described_class.new(build, ttl: 30).payload }

    it 'has correct values for the standard JWT attributes' do
      freeze_time do
        now = Time.now.to_i

        aggregate_failures do
          expect(payload[:iss]).to eq(Settings.gitlab.host)
          expect(payload[:iat]).to eq(now)
          expect(payload[:exp]).to eq(now + 30)
          expect(payload[:sub]).to eq("job_#{build.id}")
        end
      end
    end

    it 'has correct values for the custom attributes' do
      aggregate_failures do
        expect(payload[:namespace_id]).to eq(namespace.id.to_s)
        expect(payload[:namespace_path]).to eq(namespace.full_path)
        expect(payload[:project_id]).to eq(project.id.to_s)
        expect(payload[:project_path]).to eq(project.full_path)
        expect(payload[:user_id]).to eq(user.id.to_s)
        expect(payload[:user_email]).to eq(user.email)
        expect(payload[:user_login]).to eq(user.username)
        expect(payload[:pipeline_id]).to eq(pipeline.id.to_s)
        expect(payload[:pipeline_source]).to eq(pipeline.source.to_s)
        expect(payload[:job_id]).to eq(build.id.to_s)
        expect(payload[:ref]).to eq(pipeline.source_ref)
        expect(payload[:ref_protected]).to eq(build.protected.to_s)
        expect(payload[:environment]).to be_nil
        expect(payload[:environment_protected]).to be_nil
        expect(payload[:deployment_tier]).to be_nil
      end
    end

    it 'skips user related custom attributes if build has no user assigned' do
      allow(build).to receive(:user).and_return(nil)

      expect { payload }.not_to raise_error
    end

    describe 'references' do
      context 'with a branch pipepline' do
        it 'is "branch"' do
          expect(payload[:ref_type]).to eq('branch')
          expect(payload[:ref_path]).to eq('refs/heads/auto-deploy-2020-03-19')
        end
      end

      context 'with a tag pipeline' do
        let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'auto-deploy-2020-03-19', tag: true) }
        let(:build) { build_stubbed(:ci_build, :on_tag, project: project, pipeline: pipeline) }

        it 'is "tag"' do
          expect(payload[:ref_type]).to eq('tag')
          expect(payload[:ref_path]).to eq('refs/tags/auto-deploy-2020-03-19')
        end
      end

      context 'with a merge request pipeline' do
        let(:merge_request) { build_stubbed(:merge_request, source_branch: 'feature-branch') }
        let(:pipeline) { build_stubbed(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request) }

        it 'is "branch"' do
          expect(payload[:ref_type]).to eq('branch')
          expect(payload[:ref_path]).to eq('refs/heads/feature-branch')
        end
      end
    end

    describe 'ref_protected' do
      it 'is false when ref is not protected' do
        expect(build).to receive(:protected).and_return(false)

        expect(payload[:ref_protected]).to eq('false')
      end

      it 'is true when ref is protected' do
        expect(build).to receive(:protected).and_return(true)

        expect(payload[:ref_protected]).to eq('true')
      end
    end

    describe 'environment' do
      let(:environment) { build_stubbed(:environment, project: project, name: 'production', tier: 'production') }
      let(:build) do
        build_stubbed(
          :ci_build,
          project: project,
          user: user,
          pipeline: pipeline,
          environment: environment.name
        )
      end

      before do
        allow(build).to receive(:persisted_environment).and_return(environment)
      end

      it 'has correct values for environment attributes' do
        expect(payload[:environment]).to eq('production')
        expect(payload[:environment_protected]).to eq('false')
        expect(payload[:deployment_tier]).to eq('production')
      end

      describe 'deployment_tier' do
        context 'when build options specifies a different deployment_tier' do
          before do
            build.options[:environment] = { name: environment.name, deployment_tier: 'development' }
          end

          it 'uses deployment_tier from build options' do
            expect(payload[:deployment_tier]).to eq('development')
          end
        end
      end
    end
  end

  describe '.for_build' do
    shared_examples 'generating JWT for build' do
      context 'when signing key is present' do
        let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
        let_it_be(:rsa_key_data) { rsa_key.to_s }

        it 'generates JWT with key id' do
          _payload, headers = JWT.decode(jwt, rsa_key.public_key, true, { algorithm: 'RS256' })

          expect(headers['kid']).to eq(rsa_key.public_key.to_jwk['kid'])
        end

        it 'generates JWT for the given job with ttl equal to build timeout' do
          expect(build).to receive(:metadata_timeout).and_return(3_600)

          payload, _headers = JWT.decode(jwt, rsa_key.public_key, true, { algorithm: 'RS256' })
          ttl = payload["exp"] - payload["iat"]

          expect(ttl).to eq(3_600)
        end

        it 'generates JWT for the given job with default ttl if build timeout is not set' do
          expect(build).to receive(:metadata_timeout).and_return(nil)

          payload, _headers = JWT.decode(jwt, rsa_key.public_key, true, { algorithm: 'RS256' })
          ttl = payload["exp"] - payload["iat"]

          expect(ttl).to eq(5.minutes.to_i)
        end
      end

      context 'when signing key is missing' do
        let(:rsa_key_data) { nil }

        it 'raises NoSigningKeyError' do
          expect { jwt }.to raise_error described_class::NoSigningKeyError
        end
      end
    end

    subject(:jwt) { described_class.for_build(build) }

    context 'when ci_jwt_signing_key is present' do
      before do
        stub_application_setting(ci_jwt_signing_key: rsa_key_data)
      end

      it_behaves_like 'generating JWT for build'
    end
  end
end
