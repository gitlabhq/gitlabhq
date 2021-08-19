# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionService do
  describe '#execute' do
    subject { described_class.new(distribution).execute }

    let(:subject2) { described_class.new(distribution).execute }
    let(:subject3) { described_class.new(distribution).execute }

    include_context 'with published Debian package'

    [:project, :group].each do |container_type|
      context "for #{container_type}" do
        include_context 'with Debian distribution', container_type

        it_behaves_like 'Generate Debian Distribution and component files'
      end
    end
  end
end
