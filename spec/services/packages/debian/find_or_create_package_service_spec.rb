# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::FindOrCreatePackageService, feature_category: :package_registry do
  let_it_be(:distribution) { create(:debian_project_distribution, :with_suite) }
  let_it_be(:project) { distribution.project }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  let(:package) { subject.payload[:package] }
  let(:package2) { service.execute.payload[:package] }

  shared_examples 'find or create Debian package' do
    it 'returns the same object' do
      expect { subject }.to change { ::Packages::Package.count }.by(1)
      expect(subject).to be_success
      expect(package).to be_valid
      expect(package.project_id).to eq(project.id)
      expect(package.creator_id).to eq(user.id)
      expect(package.name).to eq('foo')
      expect(package.version).to eq('1.0+debian')
      expect(package).to be_debian
      expect(package.debian_publication.distribution).to eq(distribution)

      expect { package2 }.not_to change { ::Packages::Package.count }
      expect(package2.id).to eq(package.id)
    end

    context 'with package marked as pending_destruction' do
      it 'creates a new package' do
        expect { subject }.to change { ::Packages::Package.count }.by(1)

        package.pending_destruction!

        expect { package2 }.to change { ::Packages::Package.count }.by(1)
        expect(package2.id).not_to eq(package.id)
      end
    end
  end

  describe '#execute' do
    subject { service.execute }

    context 'with a codename as distribution name' do
      let(:params) { { name: 'foo', version: '1.0+debian', distribution_name: distribution.codename } }

      it_behaves_like 'find or create Debian package'
    end

    context 'with a suite as distribution name' do
      let(:params) { { name: 'foo', version: '1.0+debian', distribution_name: distribution.suite } }

      it_behaves_like 'find or create Debian package'
    end

    context 'with non-existing distribution' do
      let(:params) { { name: 'foo', version: '1.0+debian', distribution_name: 'not-existing' } }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { package }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
