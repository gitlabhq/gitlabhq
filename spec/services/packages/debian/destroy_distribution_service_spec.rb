# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::DestroyDistributionService do
  RSpec.shared_examples 'Destroy Debian Distribution' do |expected_message|
    it 'returns ServiceResponse', :aggregate_failures do
      if expected_message.nil?
        expect { response }
          .to change { container.debian_distributions.klass.all.count }
          .from(1).to(0)
          .and change { container.debian_distributions.count }
          .from(1).to(0)
          .and change { component1.class.all.count }
          .from(2).to(0)
          .and change { architecture1.class.all.count }
          .from(3).to(0)
          .and change { component_file1.class.all.count }
          .from(4).to(0)
      else
        expect { response }
          .to not_change { container.debian_distributions.klass.all.count }
          .and not_change { container.debian_distributions.count }
          .and not_change { component1.class.all.count }
          .and not_change { architecture1.class.all.count }
          .and not_change { component_file1.class.all.count }
      end

      expect(response).to be_a(ServiceResponse)
      expect(response.success?).to eq(expected_message.nil?)
      expect(response.error?).to eq(!expected_message.nil?)
      expect(response.message).to eq(expected_message)

      if expected_message.nil?
        expect(response.payload).to eq({})
      else
        expect(response.payload).to eq(distribution: distribution)
      end
    end
  end

  RSpec.shared_examples 'Debian Destroy Distribution Service' do |container_type, can_freeze|
    context "with a Debian #{container_type} distribution" do
      let_it_be(:container, freeze: can_freeze) { create(container_type) } # rubocop:disable Rails/SaveBang
      let_it_be(:distribution, freeze: can_freeze) { create("debian_#{container_type}_distribution", container: container) }
      let_it_be(:component1, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution, name: 'component1') }
      let_it_be(:component2, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution, name: 'component2') }
      let_it_be(:architecture0, freeze: true) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'all') }
      let_it_be(:architecture1, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'architecture1') }
      let_it_be(:architecture2, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'architecture2') }
      let_it_be(:component_file1, freeze: can_freeze) { create("debian_#{container_type}_component_file", :source, component: component1) }
      let_it_be(:component_file2, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1, architecture: architecture1) }
      let_it_be(:component_file3, freeze: can_freeze) { create("debian_#{container_type}_component_file", :source, component: component2) }
      let_it_be(:component_file4, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component2, architecture: architecture2) }

      subject { described_class.new(distribution) }

      let(:response) { subject.execute }

      context 'with a distribution' do
        it_behaves_like 'Destroy Debian Distribution'
      end

      context 'when destroy fails' do
        let(:distribution) { create("debian_#{container_type}_distribution", container: container) }

        before do
          expect(distribution).to receive(:destroy).and_return(false)
        end

        it_behaves_like 'Destroy Debian Distribution', "Unable to destroy Debian #{container_type} distribution"
      end
    end
  end

  it_behaves_like 'Debian Destroy Distribution Service', :project, true
  it_behaves_like 'Debian Destroy Distribution Service', :group, false
end
