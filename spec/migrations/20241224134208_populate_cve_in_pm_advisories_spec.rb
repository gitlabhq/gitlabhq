# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe PopulateCveInPmAdvisories, feature_category: :software_composition_analysis do
  let(:advisories) { table(:pm_advisories) }
  let(:migration) { described_class.new }

  before do
    advisories.create!(
      advisory_xid: '1',
      source_xid: 0,
      published_date: Date.new(2023, 1, 1),
      identifiers: [{ 'type' => 'CVE', 'name' => 'CVE-2023-1234' }]
    )
    advisories.create!(
      advisory_xid: '2',
      source_xid: 0,
      published_date: Date.new(2023, 1, 2),
      identifiers: [{ 'type' => 'CWE', 'name' => 'CWE-79' }]
    )
    advisories.create!(
      advisory_xid: '3',
      source_xid: 0,
      published_date: Date.new(2023, 1, 3),
      identifiers: [{ 'type' => 'CVE', 'name' => 'CVE-2023-5678' }, { 'type' => 'CWE', 'name' => 'CWE-89' }]
    )
    advisories.create!(
      advisory_xid: '4',
      source_xid: 0,
      published_date: Date.new(2023, 1, 4),
      identifiers: []
    )
  end

  describe 'migration' do
    it 'populates the cve column for advisories with CVE identifiers' do
      reversible_migration do |migration|
        migration.before -> {
          expect(advisories.pluck(:cve)).to match_array([nil, nil, nil, nil])
        }

        migration.after -> {
          expect(advisories.pluck(:cve)).to match_array(['CVE-2023-1234', nil, 'CVE-2023-5678', nil])
        }
      end
    end
  end
end
