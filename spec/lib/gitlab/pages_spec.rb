# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages, feature_category: :pages do
  using RSpec::Parameterized::TableSyntax

  let(:pages_secret) { SecureRandom.random_bytes(Gitlab::Pages::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(pages_secret)
  end

  describe '.verify_api_request' do
    let(:payload) { { 'iss' => 'gitlab-pages' } }

    it 'returns false if fails to validate the JWT' do
      encoded_token = JWT.encode(payload, 'wrongsecret', 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq(false)
    end

    it 'returns the decoded JWT' do
      encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq([{ "iss" => "gitlab-pages" }, { "alg" => "HS256" }])
    end
  end

  describe '.access_control_is_forced?' do
    subject { described_class.access_control_is_forced? }

    where(:access_control_is_enabled, :access_control_is_forced, :result) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        stub_pages_setting(access_control: access_control_is_enabled)
        stub_application_setting(force_pages_access_control: access_control_is_forced)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.multiple_versions_enabled_for?' do
    context 'when project is nil' do
      it 'returns false' do
        expect(described_class.multiple_versions_enabled_for?(nil)).to eq(false)
      end
    end

    context 'when a project is given' do
      let_it_be(:project) { create(:project) }

      where(:setting, :feature_flag, :license, :result) do
        false | false | false | false
        false | false | true | false
        false | true | false | false
        false | true | true | false
        true | false | false | false
        true | false | true | false
        true | true | false | false
        true | true | true | true
      end

      with_them do
        let_it_be(:project) { create(:project) }

        subject { described_class.multiple_versions_enabled_for?(project) }

        before do
          stub_licensed_features(pages_multiple_versions: license)
          stub_feature_flags(pages_multiple_versions_setting: feature_flag)
          project.project_setting.update!(pages_multiple_versions_enabled: setting)
        end

        # this feature is only available in EE
        it { is_expected.to eq(result && Gitlab.ee?) }
      end
    end
  end

  describe '#add_unique_domain_to' do
    let(:project) { build(:project) }

    context 'when pages is not enabled' do
      before do
        stub_pages_setting(enabled: false)
      end

      it 'does not set pages unique domain' do
        expect(Gitlab::Pages::RandomDomain).not_to receive(:generate)

        described_class.add_unique_domain_to(project)

        expect(project.project_setting.pages_unique_domain_enabled).to eq(false)
        expect(project.project_setting.pages_unique_domain).to eq(nil)
      end
    end

    context 'when pages is enabled' do
      before do
        stub_pages_setting(enabled: true)
      end

      it 'enables unique domain by default' do
        allow(Gitlab::Pages::RandomDomain)
          .to receive(:generate)
          .and_return('unique-domain')

        described_class.add_unique_domain_to(project)

        expect(project.project_setting.pages_unique_domain_enabled).to eq(true)
        expect(project.project_setting.pages_unique_domain).to eq('unique-domain')
      end

      context 'when project already have a unique domain' do
        it 'does not changes the original unique domain' do
          expect(Gitlab::Pages::RandomDomain).not_to receive(:generate)
          project.project_setting.update!(pages_unique_domain: 'unique-domain')

          described_class.add_unique_domain_to(project.reload)

          expect(project.project_setting.pages_unique_domain).to eq('unique-domain')
        end
      end
    end
  end
end
