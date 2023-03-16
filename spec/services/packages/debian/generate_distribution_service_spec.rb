# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionService, feature_category: :package_registry do
  include_context 'with published Debian package'

  let(:service) { described_class.new(distribution) }

  [:project, :group].each do |container_type|
    context "for #{container_type}" do
      include_context 'with Debian distribution', container_type

      describe '#execute' do
        subject { service.execute }

        let(:subject2) { described_class.new(distribution).execute }
        let(:subject3) { described_class.new(distribution).execute }

        it_behaves_like 'Generate Debian Distribution and component files'
      end

      describe '#lease_key' do
        subject { service.send(:lease_key) }

        let(:prefix) { "packages:debian:generate_distribution_service:" }

        it 'returns an unique key' do
          is_expected.to eq "#{prefix}#{container_type}_distribution:#{distribution.id}"
        end
      end
    end
  end
end
