# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OauthAccessToken, feature_category: :system_access, factory_default: :keep do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:default_user) { create_default(:user) }
  let_it_be(:app_one) { create(:oauth_application) }
  let_it_be(:app_two) { create(:oauth_application) }
  let_it_be(:app_three) { create(:oauth_application) }
  let(:organization) { build_stubbed(:organization) }

  let(:token) { create(:oauth_access_token, application_id: app_one.id) }

  describe 'scopes' do
    describe '.latest_per_application' do
      let!(:app_two_token1) { create(:oauth_access_token, application: app_two) }
      let!(:app_two_token2) { create(:oauth_access_token, application: app_two) }
      let!(:app_three_token1) { create(:oauth_access_token, application: app_three) }
      let!(:app_three_token2) { create(:oauth_access_token, application: app_three) }

      it 'returns only the latest token for each application' do
        expect(described_class.latest_per_application.map(&:id))
          .to match_array([app_two_token2.id, app_three_token2.id])
      end
    end

    describe '.preload_application' do
      before_all do
        create(:oauth_access_token, application: app_one)
        create(:oauth_access_token, application: app_two)
        create(:oauth_access_token, application: app_three)
      end

      it 'eager-loads the application owner to avoid N+1 queries' do
        records = described_class.preload_application.to_a

        expect { records.each { |record| record.application.owner } }
          .not_to exceed_query_limit(0)
      end
    end
  end

  describe 'Doorkeeper secret storing' do
    it 'does not have a prefix' do
      expect(token.plaintext_token).not_to start_with('gl')
    end

    it 'stores the token in hashed format' do
      expect(token.token).not_to eq(token.plaintext_token)
    end

    it 'does not allow falling back to plaintext token comparison' do
      expect(described_class.by_token(token.token)).to be_nil
    end

    it 'finds a token by plaintext token' do
      expect(described_class.by_token(token.plaintext_token)).to be_a(described_class)
    end

    context 'when the token is stored in plaintext' do
      let(:plaintext_token) { Devise.friendly_token(20) }

      before do
        token.update_column(:token, plaintext_token)
      end

      it 'falls back to plaintext token comparison' do
        expect(described_class.by_token(plaintext_token)).to be_a(described_class)
      end
    end
  end

  describe '.find_by_fallback_token' do
    let(:plain_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }
    let(:pbkdf2_token) { '$pbkdf2-sha512$20000$$.c0G5XJV...' }
    let(:sha512_token) { 'a' * 128 }
    let(:attr) { :token }

    context 'when token is already hashed' do
      it 'returns nil for PBKDF2 formatted tokens' do
        expect(described_class.find_by_fallback_token(attr, pbkdf2_token)).to be_nil
      end

      it 'returns nil for SHA512 formatted tokens (128 hex chars)' do
        expect(described_class.find_by_fallback_token(attr, sha512_token)).to be_nil
      end
    end

    context 'with actual fallback strategies' do
      let_it_be_with_reload(:pbkdf2_token) { create(:oauth_access_token, application: app_one) }
      let_it_be_with_reload(:sha512_token) { create(:oauth_access_token, application: app_two) }
      let_it_be_with_reload(:plain_token) { create(:oauth_access_token, application: app_three) }

      before do
        allow(described_class).to receive(:upgrade_fallback_value).and_call_original
      end

      it 'finds token stored with PBKDF2 strategy' do
        pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plain_secret)
        pbkdf2_token.update_column(:token, pbkdf2_hash)

        result = described_class.find_by_fallback_token(:token, plain_secret)

        expect(result).to eq(pbkdf2_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(pbkdf2_token, :token,
          plain_secret)
      end

      context "with FIPS mode", :fips_mode do
        it 'does not find token stored with PBKDF2 strategy' do
          pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plain_secret)
          pbkdf2_token.update_column(:token, pbkdf2_hash)

          result = described_class.find_by_fallback_token(:token, plain_secret)

          expect(result).not_to eq(pbkdf2_token)
        end
      end

      it 'finds token stored with Plain strategy when SHA512 fails' do
        # Create a different plain secret that won't match any SHA512 token
        different_secret = 'different_plain_token_xyz'
        plain_token.update_column(:token, different_secret)

        result = described_class.find_by_fallback_token(:token, different_secret)

        expect(result).to eq(plain_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(plain_token, :token,
          different_secret)
      end

      it 'upgrade legacy plain text tokens' do
        described_class.find_by_fallback_token(:token, plain_token.plaintext_token)
        sha512_hash = Gitlab::DoorkeeperSecretStoring::Sha512Hash.transform_secret(plain_token.plaintext_token)
        expect(plain_token.reload.token).to eq(sha512_hash)
      end

      it 'returns nil when no strategy finds a match' do
        non_existent_secret = 'this_token_does_not_exist_anywhere'

        result = described_class.find_by_fallback_token(:token, non_existent_secret)

        expect(result).to be_nil
        expect(described_class).not_to have_received(:upgrade_fallback_value)
      end
    end
  end

  describe '#expires_in' do
    context 'when token has expires_in value set' do
      it 'uses the expires_in value' do
        token = described_class.new(organization: organization, expires_in: 1.minute)

        expect(token).to be_valid
      end
    end

    context 'when token has nil expires_in' do
      it 'uses default value' do
        token = described_class.new(organization: organization, expires_in: nil)

        expect(token).to be_invalid
      end
    end
  end

  describe '#scope_user' do
    context 'when scopes match expected format' do
      where(:scopes) do
        [
          "user:%{user_id}",
          "other:scope user:%{user_id}",
          "user:%{user_id} other:scope",
          "api user:%{user_id} read_api"
        ]
      end

      with_them do
        let(:formatted_scopes) do
          format(scopes, user_id: default_user.id)
        end

        let(:oauth_access_token) { build_stubbed(:oauth_access_token, scopes: formatted_scopes) }

        it 'returns the user' do
          expect(oauth_access_token.scope_user).to eq default_user
        end
      end
    end

    context 'when scopes do not match composite scope format' do
      where(:scopes) do
        [
          "user:#{non_existing_record_id}",
          'fuser:%{user_id}',
          'user:%{user_id}f',
          'user:%{user_id} user:2',
          'user:not_a_number',
          'some:other:scope',
          nil,
          ""
        ]
      end
      let(:formatted_scopes) do
        if scopes.presence
          format(scopes, user_id: default_user.id)
        else
          scopes
        end
      end

      let(:oauth_access_token) { build_stubbed(:oauth_access_token, scopes: formatted_scopes) }

      with_them do
        it 'returns false' do
          expect(oauth_access_token.scope_user).to be_nil
        end
      end
    end
  end

  describe 'granular token interface', feature_category: :permissions do
    let_it_be(:project) { create(:project, developers: default_user) }
    let_it_be(:project_boundary) { Authz::Boundary.for(project) }
    let_it_be(:other_project_boundary) { Authz::Boundary.for(create(:project)) }

    let(:token) { create(:oauth_access_token, :granular, resource_owner: default_user, application: app_one) }

    def create_consent_grant(permissions)
      create(:oauth_consent_grant, user: default_user, application: app_one, boundary: project_boundary,
        permissions: permissions)
    end

    describe '#granular?' do
      where(:scopes, :granular) do
        ['granular']     | true
        %w[api granular] | true
        ['api']          | false
        []               | false
      end

      with_them do
        let(:oauth_access_token) { build_stubbed(:oauth_access_token, scopes: scopes) }

        it 'is derived from the granular scope', :aggregate_failures do
          expect(oauth_access_token.granular?).to be(granular)
          expect(oauth_access_token.legacy?).to be(!granular)
        end
      end
    end

    describe '#subject_to_granular_enforcement?' do
      it 'is false for a legacy token' do
        expect(build_stubbed(:oauth_access_token, scopes: ['api'])).not_to be_subject_to_granular_enforcement
      end

      it 'is false for a granular token' do
        expect(build_stubbed(:oauth_access_token, :granular)).not_to be_subject_to_granular_enforcement
      end
    end

    describe '#consent_grant' do
      subject(:consent_grant) { token.consent_grant }

      context 'when the user has an authorized grant for the application' do
        let_it_be(:grant) { create(:oauth_consent_grant, user: default_user, application: app_one) }

        it { is_expected.to eq(grant) }

        it 'is resolved once per token instance' do
          granular_token = token

          recorder = ActiveRecord::QueryRecorder.new { 2.times { granular_token.consent_grant } }

          expect(recorder.count).to eq(1)
        end
      end

      context 'when the grant is revoked' do
        before do
          create(:oauth_consent_grant, user: default_user, application: app_one, status: :revoked)
        end

        it { is_expected.to be_nil }
      end

      context 'when the grant is a Duo session grant' do
        before do
          create(:oauth_consent_grant, user: default_user, application: app_one, source: :duo_session)
        end

        it { is_expected.to be_nil }
      end

      context 'when the grant is for another application' do
        before do
          create(:oauth_consent_grant, user: default_user, application: app_two)
        end

        it { is_expected.to be_nil }
      end

      context 'when the grant belongs to another user' do
        before do
          create(:oauth_consent_grant, user: create(:user), application: app_one)
        end

        it { is_expected.to be_nil }
      end

      context 'when there is no grant' do
        it { is_expected.to be_nil }
      end
    end

    describe '#granular_scopes' do
      subject(:granular_scopes) { token.granular_scopes }

      context 'when the user has an authorized grant for the application' do
        let_it_be(:grant) { create_consent_grant(:create_work_item) }

        it 'returns the granular scopes of the grant' do
          expect(granular_scopes).to match_array(grant.granular_scopes)
        end
      end

      context 'when there is no authorized grant' do
        it { is_expected.to be_empty }
      end
    end

    describe '#permitted_for_boundary?' do
      subject(:permitted) { token.permitted_for_boundary?(boundary, permissions) }

      let_it_be_with_reload(:grant) { create_consent_grant(:create_work_item) }

      let(:boundary) { project_boundary }
      let(:permissions) { :create_issue }

      it { is_expected.to be(true) }

      context 'when the permission is not granted' do
        let(:permissions) { :update_wiki }

        it { is_expected.to be(false) }
      end

      context 'when the boundary is outside the grant' do
        let(:boundary) { other_project_boundary }

        it { is_expected.to be(false) }
      end

      context 'when the token is a legacy token' do
        it 'is false without resolving the consent grant' do
          legacy_token = create(:oauth_access_token, resource_owner: default_user, application: app_one,
            scopes: ['api'])

          recorder = ActiveRecord::QueryRecorder.new do
            expect(legacy_token.permitted_for_boundary?(boundary, permissions)).to be(false)
          end

          expect(recorder.count).to eq(0)
        end
      end

      context 'when the consent grant is revoked' do
        before do
          grant.revoked!
        end

        it 'fails closed while the token itself stays accessible', :aggregate_failures do
          expect(token).to be_accessible
          expect(permitted).to be(false)
        end
      end

      context 'when consent is granted again with broader permissions' do
        let(:permissions) { :update_wiki }

        before do
          grant.revoked!
          create_consent_grant([:create_work_item, :update_wiki])
        end

        it 'applies to outstanding tokens' do
          expect(permitted).to be(true)
        end
      end

      it 'resolves the consent grant and its scopes once per token instance', :aggregate_failures do
        granular_token = token

        recorder = ActiveRecord::QueryRecorder.new do
          granular_token.permitted_for_boundary?(project_boundary, :create_issue)
          granular_token.permitted_for_boundary?(other_project_boundary, :create_issue)
          granular_token.permitted_for_boundary?(project_boundary, :update_wiki)
        end

        expect(recorder.log.count { |sql| sql.include?('FROM "oauth_consent_grants"') }).to eq(1)
        expect(recorder.log.count { |sql| sql.include?('FROM "granular_scopes"') }).to eq(1)
      end
    end

    describe '#can?' do
      let_it_be(:grant) { create_consent_grant(:create_work_item) }

      it 'grants permissions included in the consent grant' do
        expect(token.can?(:create_issue, project_boundary)).to be(true)
      end

      it 'denies permissions the consent grant does not include' do
        expect(token.can?(:update_wiki, project_boundary)).to be(false)
      end
    end
  end
end
