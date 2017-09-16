require 'spec_helper'

describe ProjectAutoDevops do
  set(:project) { build(:project) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  describe '#has_domain?' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: 'domain.com') }

    it { is_expected.to have_domain }
  end

  describe '#variables' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: domain) }

    context 'when domain is defined' do
      let(:domain) { 'example.com' }

      it 'returns AUTO_DEVOPS_DOMAIN' do
        expect(auto_devops.variables).to include(
          { key: 'AUTO_DEVOPS_DOMAIN', value: 'example.com', public: true })
      end
    end
  end
end
