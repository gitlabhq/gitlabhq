# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Jwt, feature_category: :secrets_management do
  let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let_it_be(:user) { create(:user) }
  let_it_be(:job) { create(:ci_build, user: user) }
  let(:cell_id) { 1 }

  before do
    allow(Gitlab::CurrentSettings)
      .to receive(:ci_job_token_signing_key)
      .and_return(rsa_key.to_pem)
  end

  describe '.encode' do
    subject(:encoded_token) { described_class.encode(job) }

    context 'when all conditions are met' do
      it 'returns a valid JWT token' do
        expect(encoded_token).to be_present
        expect(encoded_token).to start_with(Ci::Build::TOKEN_PREFIX)
      end
    end

    context 'with instance prefix support' do
      let(:plaintext) { encoded_token }

      context 'with default instance prefix' do
        it 'starts with glcbt-' do
          expect(plaintext).to start_with(Ci::Build::TOKEN_PREFIX)
        end
      end

      context 'with custom instance prefix' do
        let_it_be(:instance_prefix) { 'instanceprefix' }

        before do
          stub_application_setting(instance_token_prefix: instance_prefix)
        end

        it 'starts with the instance prefix' do
          expect(plaintext).to start_with(instance_prefix)
        end

        it 'keeps glcbt- as part of the prefix' do
          expect(plaintext).to start_with("#{instance_prefix}-#{Ci::Build::TOKEN_PREFIX}")
        end

        context 'with feature flag custom_prefix_for_all_token_types disabled' do
          before do
            stub_feature_flags(custom_prefix_for_all_token_types: false)
          end

          it 'starts with the default prefix' do
            expect(plaintext).to start_with(Ci::Build::TOKEN_PREFIX)
          end
        end
      end
    end

    context 'when job is not a Ci::Build' do
      let(:job) { Object.new }

      it { is_expected.to be_nil }
    end

    context 'when job is not persisted' do
      let(:job) { build(:ci_build) }

      it { is_expected.to be_nil }
    end

    context 'when signing key is not available' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:ci_job_token_signing_key)
          .and_return(nil)
      end

      it 'raises an error' do
        expect { encoded_token }.to raise_error(RuntimeError, 'CI job token signing key is not set')
      end
    end

    context 'when signing key results in error' do
      before do
        allow(described_class).to receive(:key).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.decode' do
    let(:encoded_token) { described_class.encode(job) }

    subject(:decoded_token) { described_class.decode(encoded_token) }

    before do
      stub_config(cell: { enabled: true, id: cell_id })
    end

    context 'with a valid token' do
      let(:decoded_payload) { decoded_token.instance_variable_get(:@jwt).payload }
      let(:expected_payload) do
        {
          "c" => cell_id.to_s(36),
          "o" => job.project.organization_id.to_s(36),
          "u" => user.id.to_s(36),
          "p" => job.project_id.to_s(36)
        }
      end

      it 'successfully decodes the token with subject' do
        expect(decoded_token).to be_present
        expect(decoded_token.job).to eq(job)
      end

      it 'successfully decodes the token with routable payload' do
        expect(decoded_payload).to match(a_hash_including(expected_payload))
      end

      context 'when project belongs to a group' do
        let_it_be(:job) { create(:ci_build, user: user, project: create(:project, :in_group)) }

        it 'includes group id in routable payload' do
          expect(decoded_payload)
            .to match(a_hash_including(expected_payload.merge("g" => job.project.group.id.to_s(36))))
        end
      end

      context 'with custom instance prefix' do
        let_it_be(:instance_prefix) { 'instanceprefix' }

        context 'with token starting with instance prefix' do
          before do
            # set instance_prefix before creating the token, so we get a token with instance prefix:
            stub_application_setting(instance_token_prefix: instance_prefix)
          end

          it 'successfully decodes the token with subject' do
            expect(encoded_token).to start_with(instance_prefix)
            expect(decoded_token).to be_present
            expect(decoded_token.job).to eq(job)
          end
        end

        context 'with token starting with default prefix glcbt-' do
          it 'successfully decodes the token with subject' do
            expect(encoded_token).to start_with(Ci::Build::TOKEN_PREFIX)

            # To check backwards compatibility, we set the instance prefix after creating the token, so we have a token
            # with a default prefix while the system is configured to use an instance prefix
            stub_application_setting(instance_token_prefix: instance_prefix)

            expect(decoded_token).to be_present
            expect(decoded_token.job).to eq(job)
          end
        end
      end
    end

    context 'when signing key is not available' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:ci_job_token_signing_key)
          .and_return(nil)
      end

      it 'raises an error' do
        expect { decoded_token }.to raise_error(RuntimeError, 'CI job token signing key is not set')
      end
    end

    context 'when signing key results in errors' do
      before do
        allow(described_class).to receive(:key).and_return(nil)
      end

      it { is_expected.to be_nil }
    end

    context 'when token is unknown' do
      let(:encoded_token) { 'unknown-token' }

      it { is_expected.to be_nil }
    end
  end

  describe '.expire_time' do
    subject(:expire_time) { described_class.expire_time(job) }

    it 'returns expiration time with leeway' do
      freeze_time do
        allow(job).to receive(:timeout_value).and_return(2.hours)
        expected_time = Time.current + 2.hours + described_class::LEEWAY

        expect(expire_time).to eq(expected_time)
      end
    end

    it 'uses default expire time when timeout_value is smaller' do
      freeze_time do
        allow(job).to receive(:timeout_value).and_return(1.minute)

        expected_time = Time.current +
          ::JSONWebToken::Token::DEFAULT_EXPIRE_TIME +
          described_class::LEEWAY

        expect(expire_time).to eq(expected_time)
      end
    end
  end

  describe '.key' do
    subject(:key) { described_class.key }

    context 'with valid RSA key' do
      it 'returns an RSA key instance' do
        expect(key).to be_a(OpenSSL::PKey::RSA)
      end
    end

    context 'with invalid RSA key' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:ci_job_token_signing_key)
          .and_return('invalid_key')
      end

      it 'returns nil and tracks error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(OpenSSL::PKey::RSAError))

        expect(key).to be_nil
      end
    end

    context 'when signing key is not set' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:ci_job_token_signing_key)
          .and_return(nil)
      end

      it 'raises an error' do
        expect { key }
          .to raise_error('CI job token signing key is not set')
      end
    end
  end

  describe '#scoped_user' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }
    let_it_be(:scoped_user) { create(:user) }

    context 'when the job does not have scoped user' do
      it 'does not encode the scoped user in the JWT payload' do
        expect(decoded_token.scoped_user).to be_nil
      end
    end

    context 'when the job has scoped user' do
      before do
        allow(job).to receive(:scoped_user).and_return(scoped_user)
      end

      it 'encodes the scoped user in the JWT payload' do
        expect(decoded_token.scoped_user).to eq(scoped_user)
      end
    end
  end

  describe '#cell_id' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    context 'when cell is enabled' do
      before do
        stub_config(cell: { enabled: true, id: cell_id })
      end

      it 'encodes the cell_id in the JWT payload' do
        expect(decoded_token.cell_id).to eq(cell_id)
      end
    end

    context 'when cell is disabled' do
      before do
        stub_config(cell: { enabled: false, id: nil })
      end

      it 'cell_id should not be encoded' do
        expect(decoded_token.cell_id).to be_nil
      end
    end
  end

  describe '#organization_id' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    it 'encodes the organization_id in the JWT payload' do
      expect(decoded_token.organization_id).to eq(job.project.organization_id)
    end
  end

  describe '#project_id' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    it 'encodes the project_id in the JWT payload' do
      expect(decoded_token.project_id).to eq(job.project_id)
    end
  end

  describe '#user_id' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    it 'encodes the user_id in the JWT payload' do
      expect(decoded_token.user_id).to eq(job.user_id)
    end
  end

  describe '#group_id' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    context 'when project belongs to a group' do
      let_it_be(:job) { create(:ci_build, user: user, project: create(:project, :in_group)) }

      it 'encodes the group_id in the JWT payload' do
        expect(decoded_token.group_id).to eq(job.project.group.id)
      end
    end

    context 'when project belongs to a personal namespace' do
      it 'does not encode the group_id in the JWT payload' do
        expect(decoded_token.group_id).to be_nil
      end
    end
  end

  describe '#job' do
    let(:encoded_token) { described_class.encode(job) }
    let(:decoded_token) { described_class.decode(encoded_token) }

    it 'is encoded with the job as subject' do
      expect(decoded_token.job).to eq(job)
    end
  end
end
