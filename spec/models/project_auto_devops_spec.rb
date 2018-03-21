require 'spec_helper'

describe ProjectAutoDevops do
  set(:project) { build(:project) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  describe '#has_domain?' do
    context 'when domain is defined' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: 'domain.com') }

      it { expect(auto_devops).to have_domain }
    end

    context 'when domain is empty' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: '') }

      context 'when there is an instance domain specified' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:auto_devops_domain).and_return('example.com')
        end

        it { expect(auto_devops).to have_domain }
      end

      context 'when there is no instance domain specified' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:auto_devops_domain).and_return(nil)
        end

        it { expect(auto_devops).not_to have_domain }
      end
    end
  end

  describe '#predefined_variables' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: domain) }

    context 'when domain is defined' do
      let(:domain) { 'example.com' }

      it 'returns AUTO_DEVOPS_DOMAIN' do
        expect(auto_devops.predefined_variables).to include(domain_variable)
      end
    end

    context 'when domain is not defined' do
      let(:domain) { nil }

      context 'when there is an instance domain specified' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:auto_devops_domain).and_return('example.com')
        end

        it { expect(auto_devops.predefined_variables).to include(domain_variable) }
      end

      context 'when there is no instance domain specified' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:auto_devops_domain).and_return(nil)
        end

        it { expect(auto_devops.predefined_variables).not_to include(domain_variable) }
      end
    end

    def domain_variable
      { key: 'AUTO_DEVOPS_DOMAIN', value: 'example.com', public: true }
    end
  end
end
