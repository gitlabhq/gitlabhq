# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Jwt do
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
      Timecop.freeze do
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
        expect(payload[:job_id]).to eq(build.id.to_s)
        expect(payload[:ref]).to eq(pipeline.source_ref)
      end
    end

    it 'skips user related custom attributes if build has no user assigned' do
      allow(build).to receive(:user).and_return(nil)

      expect { payload }.not_to raise_error
    end

    describe 'ref type' do
      context 'branches' do
        it 'is "branch"' do
          expect(payload[:ref_type]).to eq('branch')
        end
      end

      context 'tags' do
        let(:build) { build_stubbed(:ci_build, :on_tag, project: project) }

        it 'is "tag"' do
          expect(payload[:ref_type]).to eq('tag')
        end
      end

      context 'merge requests' do
        let(:pipeline) { build_stubbed(:ci_pipeline, :detached_merge_request_pipeline) }

        it 'is "branch"' do
          expect(payload[:ref_type]).to eq('branch')
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
  end

  describe '.for_build' do
    let(:rsa_key) { OpenSSL::PKey::RSA.new(Rails.application.secrets.ci_jwt_signing_key) }

    subject(:jwt) { described_class.for_build(build) }

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
end
