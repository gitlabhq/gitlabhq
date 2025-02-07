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
    subject { described_class.access_control_is_forced?(group) }

    let(:group) { build_stubbed(:group) }

    where(:access_control_is_enabled, :access_control_is_forced, :group_enforcement, :result) do
      false | false | false | false
      false | true  | false | false
      true  | false | false | false
      true  | true  | false | true
      true  | false | true  | true
      false | false | true  | false
    end

    with_them do
      before do
        stub_pages_setting(access_control: access_control_is_enabled)
        stub_application_setting(force_pages_access_control: access_control_is_forced)
        allow(described_class).to receive(:group_level_enforcement?).with(group).and_return(group_enforcement)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.group_level_enforcement?' do
    subject { described_class.group_level_enforcement?(group) }

    let(:access_control_is_enabled) { false }

    before do
      stub_pages_setting(access_control: access_control_is_enabled)
    end

    context 'when Pages access control is enabled at instance level' do
      let(:access_control_is_enabled) { true }

      context 'when group exists' do
        let(:group) { build_stubbed(:group) }
        let(:parent_group) { build_stubbed(:group) }

        context 'when group has force_pages_access_control enabled' do
          before do
            allow(group).to receive_messages(force_pages_access_control: true, self_and_ancestors: [group])
          end

          it { is_expected.to be true }
        end

        context 'when ancestor group has force_pages_access_control enabled' do
          before do
            allow(parent_group).to receive(:force_pages_access_control).and_return(true)
            allow(group).to receive_messages(force_pages_access_control: false,
              self_and_ancestors: [group, parent_group])
          end

          it { is_expected.to be true }
        end

        context 'when no group in hierarchy has force_pages_access_control enabled' do
          before do
            allow(group).to receive_messages(force_pages_access_control: false, self_and_ancestors: [group])
          end

          it { is_expected.to be false }
        end
      end
    end

    context 'when Pages access control is disabled at instance level' do
      context 'when group is nil' do
        let(:group) { nil }

        it { is_expected.to be false }
      end

      context 'when group exists' do
        let(:group) { build_stubbed(:group) }
        let(:parent_group) { build_stubbed(:group) }

        context 'when group has force_pages_access_control enabled' do
          before do
            allow(group).to receive(:force_pages_access_control).and_return(true)
          end

          it { is_expected.to be false }
        end

        context 'when ancestor group has force_pages_access_control enabled' do
          before do
            allow(parent_group).to receive(:force_pages_access_control).and_return(true)
            allow(group).to receive_messages(force_pages_access_control: false,
              self_and_ancestors: [group, parent_group])
          end

          it { is_expected.to be false }
        end

        context 'when no group in hierarchy has force_pages_access_control enabled' do
          before do
            allow(group).to receive_messages(force_pages_access_control: false, self_and_ancestors: [group])
          end

          it { is_expected.to be false }
        end
      end
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

      where(:license, :result) do
        false | false
        true  | true
      end

      with_them do
        let_it_be(:project) { create(:project) }

        subject { described_class.multiple_versions_enabled_for?(project) }

        before do
          stub_licensed_features(pages_multiple_versions: license)
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

      context 'when a unique domain is already in use and needs to generate a new one' do
        it 'generates a different unique domain if the original is already taken' do
          allow(Gitlab::Pages::RandomDomain).to receive(:generate).and_return('existing-domain', 'new-unique-domain')

          # Simulate the existing domain being in use
          create(:project_setting, pages_unique_domain: 'existing-domain')

          described_class.add_unique_domain_to(project)

          expect(project.project_setting.pages_unique_domain_enabled).to eq(true)
          expect(project.project_setting.pages_unique_domain).to eq('new-unique-domain')
        end
      end

      RSpec.shared_examples 'generates a different unique domain' do |entity|
        let!(:existing_entity) { create(entity, path: 'existing-path') }

        context "when #{entity} path is already in use" do
          it 'assigns a different unique domain to pages' do
            allow(Gitlab::Pages::RandomDomain).to receive(:generate).and_return('existing-path', 'new-unique-domain')

            described_class.add_unique_domain_to(project)

            expect(project.project_setting.pages_unique_domain_enabled).to eq(true)
            expect(project.project_setting.pages_unique_domain).to eq('new-unique-domain')
          end
        end
      end

      it_behaves_like 'generates a different unique domain', :group
      it_behaves_like 'generates a different unique domain', :namespace

      context 'when generated 10 unique domains are already in use' do
        it 'raises an error' do
          allow(Gitlab::Pages::RandomDomain).to receive(:generate).and_return('existing-domain')

          # Simulate the existing domain being in use
          create(:project_setting, pages_unique_domain: 'existing-domain')

          expect { described_class.add_unique_domain_to(project) }.to raise_error(
            described_class::UniqueDomainGenerationFailure,
            "Can't generate unique domain for GitLab Pages"
          )

          expect(project.project_setting.pages_unique_domain).to be_nil
        end
      end
    end
  end

  describe '.generate_unique_domain' do
    let(:project) { create(:project, path: 'test-project') }

    context 'when a unique domain can be generated' do
      before do
        allow(Gitlab::Pages::RandomDomain).to receive(:generate)
          .with(project_path: project.path)
          .and_return('unique-domain-123')

        allow(ProjectSetting).to receive(:unique_domain_exists?)
          .with('unique-domain-123')
          .and_return(false)
      end

      it 'returns the generated unique domain' do
        expect(described_class.generate_unique_domain(project)).to eq('unique-domain-123')
      end

      it 'attempts generation only once when first attempt succeeds' do
        expect(Gitlab::Pages::RandomDomain).to receive(:generate).once

        described_class.generate_unique_domain(project)
      end
    end

    context 'when first attempts fail but later succeeds' do
      before do
        # First two attempts generate existing domains
        allow(Gitlab::Pages::RandomDomain).to receive(:generate)
          .with(project_path: project.path)
          .and_return('existing-domain-1', 'existing-domain-2', 'unique-domain-123')

        allow(ProjectSetting).to receive(:unique_domain_exists?)
          .with('existing-domain-1').and_return(true)
        allow(ProjectSetting).to receive(:unique_domain_exists?)
          .with('existing-domain-2').and_return(true)
        allow(ProjectSetting).to receive(:unique_domain_exists?)
          .with('unique-domain-123').and_return(false)
      end

      it 'returns the first unique domain generated' do
        expect(described_class.generate_unique_domain(project)).to eq('unique-domain-123')
      end
    end

    context 'when unique domain generation fails after all attempts' do
      before do
        allow(Gitlab::Pages::RandomDomain).to receive(:generate)
          .with(project_path: project.path)
          .and_return('existing-domain')

        allow(ProjectSetting).to receive(:unique_domain_exists?)
          .with('existing-domain')
          .and_return(true)
      end

      it 'raises UniqueDomainGenerationFailure after 10 attempts' do
        expect(Gitlab::Pages::RandomDomain).to receive(:generate).exactly(10).times

        expect { described_class.generate_unique_domain(project) }
          .to raise_error(Gitlab::Pages::UniqueDomainGenerationFailure)
      end
    end

    context 'when project is nil' do
      it 'raises NoMethodError' do
        expect { described_class.generate_unique_domain(nil) }
          .to raise_error(NoMethodError)
      end
    end
  end

  describe '#update_primary_domain' do
    let(:project) { build(:project) }

    context 'when pages is not enabled' do
      before do
        stub_pages_setting(enabled: false)
      end

      it 'does not set pages primary domain' do
        expect do
          described_class.update_primary_domain(project, 'http://example.com')
        end.not_to change { project.project_setting.pages_primary_domain }
      end
    end

    context 'when pages is enabled' do
      before do
        stub_pages_setting(enabled: true)
      end

      it 'sets pages primary domain' do
        expect do
          described_class.update_primary_domain(project, 'http://example.com')
        end.to change { project.project_setting.pages_primary_domain }.from(nil).to('http://example.com')
      end

      context 'when pages primary domain is updated with blank' do
        before do
          stub_pages_setting(enabled: true)
        end

        it 'sets pages primary domain as nil' do
          project.project_setting.update!(pages_primary_domain: 'http://example.com')

          expect do
            described_class.update_primary_domain(project, '')
          end.to change { project.project_setting.pages_primary_domain }.from('http://example.com').to(nil)
        end
      end
    end
  end
end
