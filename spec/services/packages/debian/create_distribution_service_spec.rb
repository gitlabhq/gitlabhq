# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::CreateDistributionService, feature_category: :package_registry do
  RSpec.shared_examples 'Create Debian Distribution' do |expected_message, expected_components, expected_architectures|
    let_it_be(:container) { create(container_type) } # rubocop:disable Rails/SaveBang

    it 'returns ServiceResponse', :aggregate_failures do
      if expected_message.nil?
        expect(::Packages::Debian::GenerateDistributionWorker).to receive(:perform_async).with(container_type, an_instance_of(Integer))

        expect { response }
          .to change { container.debian_distributions.klass.all.count }
          .from(0).to(1)
          .and change { container.debian_distributions.count }
          .from(0).to(1)
          .and change { container.debian_distributions.first&.components&.count }
          .from(nil).to(expected_components.count)
          .and change { container.debian_distributions.first&.architectures&.count }
          .from(nil).to(expected_architectures.count)
          .and not_change { Packages::Debian::ProjectComponentFile.count }
          .and not_change { Packages::Debian::GroupComponentFile.count }
      else
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { response }
          .to not_change { container.debian_distributions.klass.all.count }
          .and not_change { container.debian_distributions.count }
          .and not_change { Packages::Debian::ProjectComponent.count }
          .and not_change { Packages::Debian::GroupComponent.count }
          .and not_change { Packages::Debian::ProjectArchitecture.count }
          .and not_change { Packages::Debian::GroupArchitecture.count }
          .and not_change { Packages::Debian::ProjectComponentFile.count }
          .and not_change { Packages::Debian::GroupComponentFile.count }
      end

      expect(response).to be_a(ServiceResponse)
      expect(response.success?).to eq(expected_message.nil?)
      expect(response.error?).to eq(!expected_message.nil?)
      expect(response.message).to eq(expected_message)

      distribution = response.payload[:distribution]
      expect(distribution.persisted?).to eq(expected_message.nil?)
      expect(distribution.container).to eq(container)
      expect(distribution.creator).to eq(user)
      params.each_pair do |name, value|
        expect(distribution.send(name)).to eq(value)
      end

      expect(distribution.components.map(&:name)).to contain_exactly(*expected_components)
      expect(distribution.architectures.map(&:name)).to contain_exactly(*expected_architectures)
    end
  end

  shared_examples 'Debian Create Distribution Service' do
    context 'with only the codename param' do
      let(:params) { { codename: 'my-codename' } }

      it_behaves_like 'Create Debian Distribution', nil, %w[main], %w[all amd64]
    end

    context 'with codename, components and architectures' do
      let(:params) do
        {
          codename: 'my-codename',
          components: %w[contrib non-free],
          architectures: %w[arm64]
        }
      end

      it_behaves_like 'Create Debian Distribution', nil, %w[contrib non-free], %w[all arm64]
    end

    context 'with invalid suite' do
      let(:params) do
        {
          codename: 'my-codename',
          suite: 'erroné'
        }
      end

      it_behaves_like 'Create Debian Distribution', 'Suite is invalid', %w[], %w[]
    end

    context 'with invalid component name' do
      let(:params) do
        {
          codename: 'my-codename',
          components: %w[before erroné after],
          architectures: %w[arm64]
        }
      end

      it_behaves_like 'Create Debian Distribution', 'Component Name is invalid', %w[before erroné], %w[]
    end

    context 'with invalid architecture name' do
      let(:params) do
        {
          codename: 'my-codename',
          components: %w[contrib non-free],
          architectures: %w[before erroné after']
        }
      end

      it_behaves_like 'Create Debian Distribution', 'Architecture Name is invalid', %w[contrib non-free], %w[before erroné]
    end
  end

  let_it_be(:user) { create(:user) }

  subject { described_class.new(container, user, params) }

  let(:response) { subject.execute }

  context 'within a projet' do
    let_it_be(:container_type) { :project }

    it_behaves_like 'Debian Create Distribution Service'
  end

  context 'within a group' do
    let_it_be(:container_type) { :group }

    it_behaves_like 'Debian Create Distribution Service'
  end
end
