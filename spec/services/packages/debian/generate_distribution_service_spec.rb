# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionService do
  describe '#execute' do
    subject { described_class.new(distribution).execute }

    include_context 'with published Debian package'

    [:project, :group].each do |container_type|
      context "for #{container_type}" do
        include_context 'with Debian distribution', container_type

        context 'with Debian components and architectures' do
          it_behaves_like 'Generate Debian Distribution and component files'
        end

        context 'without components and architectures' do
          it_behaves_like 'Generate minimal Debian Distribution'
        end
      end
    end
  end
end
