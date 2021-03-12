# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::FindOrCreateIncomingService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject(:package) { service.execute }

    context 'run once' do
      it 'creates a new package', :aggregate_failures do
        expect(package).to be_valid
        expect(package.project_id).to eq(project.id)
        expect(package.creator_id).to eq(user.id)
        expect(package.name).to eq('incoming')
        expect(package.version).to be_nil
        expect(package.package_type).to eq('debian')
        expect(package.debian_incoming?).to be_truthy
      end

      it_behaves_like 'assigns the package creator'
    end

    context 'run twice' do
      let!(:package2) { service.execute }

      it 'returns the same object' do
        expect(package2.id).to eq(package.id)
      end
    end
  end
end
