# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::FindOrCreatePackageService do
  let_it_be(:distribution) { create(:debian_project_distribution) }
  let_it_be(:project) { distribution.project }
  let_it_be(:user) { create(:user) }

  let(:params) { { name: 'foo', version: '1.0+debian', distribution_name: distribution.codename } }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    subject { service.execute }

    let(:package) { subject.payload[:package] }

    context 'run once' do
      it 'creates a new package', :aggregate_failures do
        expect { subject }.to change { ::Packages::Package.count }.by(1)
        expect(subject).to be_success

        expect(package).to be_valid
        expect(package.project_id).to eq(project.id)
        expect(package.creator_id).to eq(user.id)
        expect(package.name).to eq('foo')
        expect(package.version).to eq('1.0+debian')
        expect(package).to be_debian
        expect(package.debian_publication.distribution).to eq(distribution)
      end
    end

    context 'run twice' do
      let(:subject2) { service.execute }

      let(:package2) { service.execute.payload[:package] }

      it 'returns the same object' do
        expect { subject }.to change { ::Packages::Package.count }.by(1)
        expect { package2 }.not_to change { ::Packages::Package.count }

        expect(package2.id).to eq(package.id)
      end
    end

    context 'with non-existing distribution' do
      let(:params) { { name: 'foo', version: '1.0+debian', distribution_name: 'not-existing' } }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { package }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
