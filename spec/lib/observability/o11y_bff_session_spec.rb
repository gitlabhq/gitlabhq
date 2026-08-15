# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::O11yBffSession, feature_category: :observability do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let_it_be(:o11y_application) { create(:oauth_application) }

  let(:o11y_settings) do
    instance_double(
      Observability::GroupO11ySetting,
      o11y_service_url: 'https://o11y.example.com',
      group: group
    )
  end

  let(:assertion) { { id_token: 'signed.id.token' } }

  let(:success_body) do
    Gitlab::Json.dump({ 'data' => { 'accessToken' => 'access_jwt_1', 'refreshToken' => 'refresh_jwt_1' } })
  end

  let(:success_response) { instance_double(HTTParty::Response, code: 200, body: success_body) }

  subject(:service) { described_class.new(o11y_settings: o11y_settings, user: owner, access_resource: group) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
    group.add_developer(developer)
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:o11y_oauth_application).and_return(o11y_application)

    # Isolate the Doorkeeper/OIDC minting seam.
    allow(service).to receive(:mint_gitlab_assertion).and_return(assertion)
  end

  describe '#generate_tokens' do
    context 'when the SigNoz exchange succeeds' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(success_response)
      end

      it 'POSTs the assertion to the SigNoz BFF endpoint with the expected payload' do
        expect(Gitlab::HTTP).to receive(:post).with(
          'https://o11y.example.com/api/v1/complete/gitlab/bff',
          hash_including(
            body: a_string_including('"idToken":"signed.id.token"')
              .and(a_string_including('"ref":"https://o11y.example.com"'))
          )
        ).and_return(success_response)

        service.generate_tokens
      end

      it 'does not send role as a sibling request field' do
        # role travels as a signed id_token claim (see #mint_gitlab_assertion),
        # never as an unsigned request body field -- see
        # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
        expect(Gitlab::HTTP).to receive(:post) do |_url, options|
          expect(Gitlab::Json::SafeParser.parse(options[:body])).not_to have_key('role')
          success_response
        end

        service.generate_tokens
      end

      it 'does not include orgId, domainId, or accessToken in the payload' do
        expect(Gitlab::HTTP).to receive(:post) do |_url, options|
          expect(options[:body]).not_to include('orgId')
          expect(options[:body]).not_to include('domainId')
          expect(options[:body]).not_to include('accessToken')
          success_response
        end

        service.generate_tokens
      end

      it 'returns the per-user tokens' do
        expect(service.generate_tokens).to eq(accessJwt: 'access_jwt_1', refreshJwt: 'refresh_jwt_1')
      end
    end

    context 'when mapping access levels to SigNoz roles' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(success_response)
      end

      where(:member, :expected_role) do
        ref(:owner)      | 'ADMIN'
        ref(:maintainer) | 'EDITOR'
        ref(:developer)  | 'EDITOR'
      end

      with_them do
        subject(:service) { described_class.new(o11y_settings: o11y_settings, user: member, access_resource: group) }

        it 'passes the expected role into mint_gitlab_assertion, to be signed into the id_token' do
          # role is signed into the id_token by mint_gitlab_assertion (see
          # #signed_id_token) rather than sent as a plaintext request field,
          # so we assert on the argument passed to the minting seam instead
          # of inspecting the outgoing HTTP body -- see
          # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
          expect(service).to receive(:mint_gitlab_assertion).with(expected_role).and_return(assertion)

          service.generate_tokens
        end
      end

      context 'when the user has access through an ancestor group membership' do
        let_it_be(:subgroup) { create(:group, parent: group) }

        subject(:service) do
          described_class.new(o11y_settings: o11y_settings, user: maintainer, access_resource: subgroup)
        end

        it 'resolves the role through the inherited membership' do
          expect(service).to receive(:mint_gitlab_assertion).with('EDITOR').and_return(assertion)

          service.generate_tokens
        end
      end

      context 'when the user has access through a group share' do
        let_it_be(:invited_group) { create(:group) }
        let_it_be(:shared_user) { create(:user) }

        subject(:service) do
          described_class.new(o11y_settings: o11y_settings, user: shared_user, access_resource: group)
        end

        before_all do
          invited_group.add_maintainer(shared_user)
          create(:group_group_link, :developer, shared_group: group, shared_with_group: invited_group)
        end

        it 'resolves the role capped at the group-share access level' do
          expect(service).to receive(:mint_gitlab_assertion).with('EDITOR').and_return(assertion)

          service.generate_tokens
        end
      end

      context 'when access_resource is a project' do
        let_it_be(:project) { create(:project, group: group) }

        subject(:service) do
          described_class.new(o11y_settings: o11y_settings, user: maintainer, access_resource: project)
        end

        it 'resolves the role through the project team' do
          expect(service).to receive(:mint_gitlab_assertion).with('EDITOR').and_return(assertion)

          service.generate_tokens
        end
      end

      context 'when the user has less than Developer access' do
        let_it_be(:reporter) { create(:user) }

        subject(:service) { described_class.new(o11y_settings: o11y_settings, user: reporter, access_resource: group) }

        before_all do
          group.add_reporter(reporter)
        end

        it 'tracks an UnexpectedRoleError distinctly and returns an empty hash' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(instance_of(described_class::UnexpectedRoleError), user_id: reporter.id)
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          expect(service.generate_tokens).to eq({})
        end

        it 'does not attempt the SigNoz exchange' do
          expect(Gitlab::HTTP).not_to receive(:post)

          service.generate_tokens
        end
      end
    end

    context 'when the SigNoz exchange returns a non-200' do
      let(:error_response) { instance_double(HTTParty::Response, code: 403, body: 'forbidden') }

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(error_response)
      end

      it 'returns an empty hash' do
        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when the SigNoz response is missing tokens' do
      let(:empty_response) do
        instance_double(HTTParty::Response, code: 200, body: Gitlab::Json.dump({ 'data' => {} }))
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(empty_response)
      end

      it 'returns an empty hash' do
        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when the SigNoz response body is malformed JSON' do
      # Gitlab::Json::SafeParser.parse raises JSON::ParserError on genuinely
      # malformed input (it only returns nil for an empty string or the
      # literal "null") -- confirmed via
      #   Gitlab::Json::SafeParser.parse('not json')      # => raises
      #   Gitlab::Json::SafeParser.parse('')               # => nil
      #   Gitlab::Json::SafeParser.parse('null')           # => nil
      # so #parse_response's rescue JSON::ParserError clause below is
      # reachable and this covers it -- e.g. a proxy error page or a
      # truncated write returned with a 200 status.
      let(:malformed_response) do
        instance_double(HTTParty::Response, code: 200, body: '{"data": {"accessToken": }')
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(malformed_response)
      end

      it 'logs an AuthenticationError and returns an empty hash' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(described_class::AuthenticationError))

        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when the HTTP call raises' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(SocketError.new('boom'))
      end

      it 'logs and returns an empty hash' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(described_class::NetworkError))

        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when configuration is incomplete' do
      before do
        allow(o11y_settings).to receive(:o11y_service_url).and_return(nil)
      end

      it 'logs and returns an empty hash' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(described_class::ConfigurationError))

        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when the SigNoz OAuth application is not configured' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:o11y_oauth_application).and_return(nil)
      end

      it 'logs and returns an empty hash' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(described_class::ConfigurationError))

        expect(service.generate_tokens).to eq({})
      end
    end

    context 'when o11y_service_url is not a valid HTTPS URL' do
      # blank is already covered by the "configuration is incomplete" context above
      where(:invalid_url) do
        ['http://o11y.example.com', 'not-a-url', 'ftp://o11y.example.com']
      end

      with_them do
        before do
          allow(o11y_settings).to receive(:o11y_service_url).and_return(invalid_url)
        end

        it 'logs a ConfigurationError and returns an empty hash' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(described_class::ConfigurationError))

          expect(service.generate_tokens).to eq({})
        end

        it 'does not attempt the SigNoz exchange' do
          expect(Gitlab::HTTP).not_to receive(:post)

          service.generate_tokens
        end
      end
    end

    describe '#mint_gitlab_assertion' do
      # Exercises the real Doorkeeper/OIDC signing path (not stubbed) to
      # verify role and instance are bound inside the signed id_token rather
      # than left to an unsigned request field -- see
      # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/159
      subject(:service) { described_class.new(o11y_settings: o11y_settings, user: owner, access_resource: group) }

      before do
        # Unstub the minting seam for this context only.
        allow(service).to receive(:mint_gitlab_assertion).and_call_original
        allow(Gitlab::HTTP).to receive(:post).and_return(success_response)
      end

      def decoded_claims(id_token)
        public_key = Doorkeeper::OpenidConnect.signing_key.public_key
        JWT.decode(id_token, public_key, true, algorithm: Doorkeeper::OpenidConnect.signing_algorithm.to_s).first
      end

      it 'signs the resolved role into the id_token as a custom claim' do
        assertion = service.send(:mint_gitlab_assertion, 'ADMIN')

        claims = decoded_claims(assertion[:id_token])
        expect(claims['https://gitlab.org/claims/o11y/role']).to eq('ADMIN')
      end

      it 'signs the instance (o11y_service_url) into the id_token as a custom claim' do
        assertion = service.send(:mint_gitlab_assertion, 'EDITOR')

        claims = decoded_claims(assertion[:id_token])
        expect(claims['https://gitlab.org/claims/o11y/instance']).to eq('https://o11y.example.com')
      end

      it 'signs a unique jti claim into the id_token' do
        # jti lets SigNoz reject a replayed token (documentation#160 Tier 0)
        # -- verify it's present and that two separate mints never collide.
        first = decoded_claims(service.send(:mint_gitlab_assertion, 'EDITOR')[:id_token])
        second = decoded_claims(service.send(:mint_gitlab_assertion, 'EDITOR')[:id_token])

        expect(first['jti']).to be_present
        expect(second['jti']).to be_present
        expect(first['jti']).not_to eq(second['jti'])
      end

      it 'signs a short expiry into the id_token, distinct from the default OIDC id_token TTL' do
        # The BFF exchange is a single synchronous request/response, so the
        # token only needs to survive that round trip -- see
        # Observability::O11yBffSession::BFF_TOKEN_TTL.
        assertion = service.send(:mint_gitlab_assertion, 'EDITOR')

        claims = decoded_claims(assertion[:id_token])
        expect(claims['exp'] - claims['iat']).to eq(Observability::O11yBffSession::BFF_TOKEN_TTL.to_i)
      end

      it 'revokes the minted access token after use' do
        service.send(:mint_gitlab_assertion, 'EDITOR')

        expect(Doorkeeper::AccessToken.last).to be_revoked
      end

      it 'logs and does not raise when revoking the access token fails' do
        allow_next_instance_of(Doorkeeper::AccessToken) do |token|
          allow(token).to receive(:revoke).and_raise(ActiveRecord::StatementInvalid.new('db down'))
        end

        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(ActiveRecord::StatementInvalid), user_id: owner.id)

        expect { service.send(:mint_gitlab_assertion, 'EDITOR') }.not_to raise_error
      end

      it 'produces a token that fails signature verification if role is tampered with post-signing' do
        assertion = service.send(:mint_gitlab_assertion, 'EDITOR')
        header, payload, signature = assertion[:id_token].split('.')

        tampered_payload = Base64.urlsafe_encode64(
          Gitlab::Json::SafeParser.parse(Base64.urlsafe_decode64(payload)).merge(
            'https://gitlab.org/claims/o11y/role' => 'ADMIN'
          ).to_json,
          padding: false
        )
        tampered_token = [header, tampered_payload, signature].join('.')

        expect { decoded_claims(tampered_token) }.to raise_error(JWT::VerificationError)
      end
    end

    context 'when handling the mTLS client certificate' do
      let(:cert_path) { Tempfile.new('bff-cert').path }
      let(:key_path) { Tempfile.new('bff-key').path }
      let(:dedicated_url) { 'https://bff.o11y.example.com:8443/api/v1/complete/gitlab/bff' }
      let(:fallback_url) { 'https://o11y.example.com/api/v1/complete/gitlab/bff' }

      after do
        FileUtils.rm_f(cert_path)
        FileUtils.rm_f(key_path)
      end

      def stub_mtls_config(enabled:, listener:, cert:)
        stub_config(observability: {
          bff_mtls: {
            enabled: enabled,
            certificate_file: cert ? cert_path : nil,
            private_key_file: cert ? key_path : nil,
            listener_host: listener ? 'bff.o11y.example.com' : nil,
            listener_port: listener ? 8443 : nil
          }
        })
      end

      before do
        File.write(cert_path, "cert-content\n")
        File.write(key_path, "key-content\n")
        allow(Gitlab::HTTP).to receive(:post).and_return(success_response)
      end

      context 'when mTLS is enabled and fully configured' do
        before do
          stub_mtls_config(enabled: true, listener: true, cert: true)
        end

        it 'targets the dedicated listener and presents the client cert' do
          expect(Gitlab::HTTP).to receive(:post)
            .with(dedicated_url, hash_including(pem: "cert-content\n\nkey-content\n"))
            .and_return(success_response)

          service.generate_tokens
        end
      end

      context 'when mTLS is disabled' do
        before do
          stub_mtls_config(enabled: false, listener: false, cert: false)
        end

        it 'falls back to o11y_service_url with no client cert' do
          expect(Gitlab::HTTP).to receive(:post)
            .with(fallback_url, hash_not_including(:pem))
            .and_return(success_response)

          service.generate_tokens
        end
      end

      context 'when mTLS is enabled but incompletely configured' do
        # Fail closed: an enabled-but-broken mTLS configuration (config
        # drift, cert rotation failure) must not silently revert the
        # exchange to the unprotected fallback channel.
        where(:listener, :cert) do
          true  | false
          false | true
          false | false
        end

        with_them do
          before do
            stub_mtls_config(enabled: true, listener: listener, cert: cert)
          end

          it 'logs a ConfigurationError and returns an empty hash without calling SigNoz' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception)
              .with(instance_of(described_class::ConfigurationError))
            expect(Gitlab::HTTP).not_to receive(:post)

            expect(service.generate_tokens).to eq({})
          end
        end
      end

      context 'when a cert file disappears between the existence check and the read' do
        before do
          stub_mtls_config(enabled: true, listener: true, cert: true)
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(cert_path).and_raise(Errno::ENOENT, cert_path)
        end

        it 'logs a ConfigurationError and returns an empty hash' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(described_class::ConfigurationError))

          expect(service.generate_tokens).to eq({})
        end
      end
    end
  end
end
