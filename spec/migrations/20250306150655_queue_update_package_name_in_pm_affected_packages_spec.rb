# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueUpdatePackageNameInPmAffectedPackages, feature_category: :dependency_management do
  let(:pm_advisories) { table(:pm_advisories) }
  let(:pm_affected_packages) { table(:pm_affected_packages) }
  let(:advisory_1) do
    pm_advisories.create!(advisory_xid: 'xid', source_xid: 'xid', identifiers: [], published_date: Date.current)
  end

  let(:affected_package_1) do
    pm_affected_packages.create!(pm_advisory_id: advisory_1.id, purl_type: 8, package_name: 'Django',
      affected_range: '>1')
  end

  let(:affected_package_2) do
    pm_affected_packages.create!(pm_advisory_id: advisory_1.id, purl_type: 6, package_name: 'Django',
      affected_range: '>1')
  end

  let(:affected_package_3) do
    pm_affected_packages.create!(pm_advisory_id: advisory_1.id, purl_type: 8, package_name: 'accesscontrol',
      affected_range: '>1')
  end

  let!(:affected_packages) { [affected_package_1, affected_package_2, affected_package_3] }

  describe '#up' do
    subject(:migration) do
      described_class.new
    end

    it 'updates package_name with its normalized value' do
      migration.up

      expect(affected_package_1.reload.package_name).to eq('django')
    end

    it 'does not update those records with a different purl_type' do
      expect { migration.up }.not_to change { affected_package_2.reload.package_name }
    end

    it 'does not update those records that does not match the regex' do
      expect { migration.up }.not_to change { affected_package_3.reload.package_name }
    end

    context 'with existing record matching (pm_advisory_id, purl_type, package_name, distro_version)' do
      before do
        pm_affected_packages.create!(pm_advisory_id: advisory_1.id, purl_type: 8, package_name: 'django',
          affected_range: '>1')
      end

      it 'does not update the record that could violate DB constraint' do
        expect { migration.up }.not_to change { affected_package_1.reload.package_name }
      end
    end
  end
end
