# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::UpdateDistributionService, feature_category: :package_registry do
  RSpec.shared_examples 'Update Debian Distribution' do |expected_message, expected_components, expected_architectures, component_file_delta = 0|
    it 'returns ServiceResponse', :aggregate_failures do
      expect(distribution).to receive(:update).with(simple_params).and_call_original if expected_message.nil?
      expect(::Packages::Debian::GenerateDistributionWorker).to receive(:perform_async).with(distribution.class.container_type, distribution.id).and_call_original if expected_message.nil?
      expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async) unless expected_message.nil?

      if component_file_delta.zero?
        expect { response }
          .to not_change { container.debian_distributions.klass.all.count }
          .and not_change { container.debian_distributions.count }
          .and not_change { component1.class.all.count }
          .and not_change { architecture1.class.all.count }
          .and not_change { component_file1.class.all.count }
      else
        expect { response }
          .to not_change { container.debian_distributions.klass.all.count }
          .and not_change { container.debian_distributions.count }
          .and not_change { component1.class.all.count }
          .and not_change { architecture1.class.all.count }
          .and change { component_file1.class.all.count }
          .from(4).to(4 + component_file_delta)
      end

      expect(response).to be_a(ServiceResponse)
      expect(response.success?).to eq(expected_message.nil?)
      expect(response.error?).to eq(!expected_message.nil?)
      expect(response.message).to eq(expected_message)

      expect(response.payload).to eq(distribution: distribution)

      distribution.reload
      distribution.components.reload
      distribution.architectures.reload

      if expected_message.nil?
        simple_params.each_pair do |name, value|
          expect(distribution.send(name)).to eq(value)
        end
      else
        original_params.each_pair do |name, value|
          expect(distribution.send(name)).to eq(value)
        end
      end

      expect(distribution.components.map(&:name)).to contain_exactly(*expected_components)
      expect(distribution.architectures.map(&:name)).to contain_exactly(*expected_architectures)
    end
  end

  RSpec.shared_examples 'Debian Update Distribution Service' do |container_type, can_freeze|
    context "with a Debian #{container_type} distribution" do
      let_it_be(:container, freeze: can_freeze) { create(container_type) } # rubocop:disable Rails/SaveBang
      let_it_be(:distribution, reload: true) { create("debian_#{container_type}_distribution", container: container) }
      let_it_be(:component1) { create("debian_#{container_type}_component", distribution: distribution, name: 'component1') }
      let_it_be(:component2) { create("debian_#{container_type}_component", distribution: distribution, name: 'component2') }
      let_it_be(:architecture0) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'all') }
      let_it_be(:architecture1) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'architecture1') }
      let_it_be(:architecture2) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'architecture2') }
      let_it_be(:component_file1) { create("debian_#{container_type}_component_file", :sources, component: component1) }
      let_it_be(:component_file2) { create("debian_#{container_type}_component_file", component: component1, architecture: architecture1) }
      let_it_be(:component_file3) { create("debian_#{container_type}_component_file", :sources, component: component2) }
      let_it_be(:component_file4) { create("debian_#{container_type}_component_file", component: component2, architecture: architecture2) }

      let(:original_params) do
        {
          suite: nil,
          origin: nil,
          label: nil,
          version: nil,
          description: nil,
          valid_time_duration_seconds: nil,
          automatic: true,
          automatic_upgrades: false
        }
      end

      let(:params) { {} }
      let(:simple_params) { params.except(:components, :architectures) }

      subject { described_class.new(distribution, params) }

      let(:response) { subject.execute }

      context 'with valid simple params' do
        let(:params) do
          {
            suite: 'my-suite',
            origin: 'my-origin',
            label: 'my-label',
            version: '42.0',
            description: 'my-description',
            valid_time_duration_seconds: 7.days,
            automatic: false,
            automatic_upgrades: true
          }
        end

        it_behaves_like 'Update Debian Distribution', nil, %w[component1 component2], %w[all architecture1 architecture2]
      end

      context 'with invalid simple params' do
        let(:params) do
          {
            suite: 'suite erronée',
            origin: 'origin erronée',
            label: 'label erronée',
            version: 'version erronée',
            description: 'description erronée',
            valid_time_duration_seconds: 1.hour
          }
        end

        it_behaves_like 'Update Debian Distribution', 'Suite is invalid, Origin is invalid, Label is invalid, Version is invalid, and Valid time duration seconds must be greater than or equal to 86400', %w[component1 component2], %w[all architecture1 architecture2]
      end

      context 'with valid components and architectures' do
        let(:params) do
          {
            suite: 'my-suite',
            components: %w[component2 component3],
            architectures: %w[architecture2 architecture3]
          }
        end

        it_behaves_like 'Update Debian Distribution', nil, %w[component2 component3], %w[all architecture2 architecture3], -2
      end

      context 'with invalid components' do
        let(:params) do
          {
            suite: 'my-suite',
            components: %w[component2 erroné],
            architectures: %w[architecture2 architecture3]
          }
        end

        it_behaves_like 'Update Debian Distribution', 'Component Name is invalid', %w[component1 component2], %w[all architecture1 architecture2]
      end

      context 'with invalid architectures' do
        let(:params) do
          {
            suite: 'my-suite',
            components: %w[component2 component3],
            architectures: %w[architecture2 erroné]
          }
        end

        it_behaves_like 'Update Debian Distribution', 'Architecture Name is invalid', %w[component1 component2], %w[all architecture1 architecture2]
      end
    end
  end

  it_behaves_like 'Debian Update Distribution Service', :project, true
  it_behaves_like 'Debian Update Distribution Service', :group, false
end
