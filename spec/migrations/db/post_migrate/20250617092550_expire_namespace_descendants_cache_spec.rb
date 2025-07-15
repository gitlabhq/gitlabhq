# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ExpireNamespaceDescendantsCache, migration: :gitlab_main, feature_category: :database do
  let(:migration) { described_class.new }

  let(:namespace_descendants) { table(:namespace_descendants) }

  let(:outdated_at) { Date.new(2022, 1, 1) }
  let!(:ns_outdated) { namespace_descendants.create!(namespace_id: 1, outdated_at: outdated_at) }
  let!(:ns_up_to_date) { namespace_descendants.create!(namespace_id: 2) }

  describe '#up' do
    it 'bumps all timestamp values' do
      migrate!

      records = namespace_descendants.all
      outdated_ats = records.map(&:outdated_at)
      expect(outdated_ats).to all(be_present)
    end
  end
end
