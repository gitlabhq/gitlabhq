# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::DiffblueCover do
  let_it_be(:project) { build(:project) }

  subject(:integration) { build(:diffblue_cover_integration, project: project) }

  describe 'Validations' do
    context 'when active' do
      before do
        integration.active = true
      end

      it { is_expected.to validate_presence_of(:diffblue_license_key) }
      it { is_expected.to validate_presence_of(:diffblue_access_token_name) }
      it { is_expected.to validate_presence_of(:diffblue_access_token_secret) }
    end

    context 'when inactive' do
      before do
        integration.active = false
      end

      it { is_expected.not_to validate_presence_of(:diffblue_license_key) }
      it { is_expected.not_to validate_presence_of(:diffblue_access_token_name) }
      it { is_expected.not_to validate_presence_of(:diffblue_access_token_secret) }
    end
  end

  describe '#avatar_url' do
    it 'returns the avatar image path' do
      expect(integration.avatar_url).to eq(ActionController::Base.helpers.image_path(
        'illustrations/third-party-logos/integrations-logos/diffblue.svg'
      ))
    end
  end

  describe '#ci-vars' do
    let(:ci_vars) do
      [
        { key: 'DIFFBLUE_LICENSE_KEY', value: '1234-ABCD-DCBA-4321', public: false, masked: true },
        { key: 'DIFFBLUE_ACCESS_TOKEN_NAME', value: 'Diffblue CI', public: false, masked: true },
        { key: 'DIFFBLUE_ACCESS_TOKEN',
          value: 'glpat-00112233445566778899', public: false, masked: true } # gitleaks:allow
      ]
    end

    context 'when active' do
      before do
        integration.active = true
      end

      it 'returns the required pipeline vars' do
        expect(integration.ci_variables).to match_array(ci_vars)
      end
    end

    context 'when inactive' do
      before do
        integration.active = false
      end

      it 'does not return the required pipeline vars' do
        expect(integration.ci_variables).to be_empty
      end
    end
  end

  describe '#diffblue_link' do
    it { expect(described_class.diffblue_link).to include("https://www.diffblue.com/try-cover/gitlab/") }
  end
end
