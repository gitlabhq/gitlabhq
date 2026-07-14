# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Tokens::EnforcementCache, :request_store, feature_category: :permissions do
  let_it_be(:enforced_group) do
    create(:group).tap do |group|
      group.namespace_settings.update!(
        enforce_granular_tokens: true,
        granular_tokens_enforced_after: Date.current
      )
    end
  end

  let_it_be(:unenforced_group) { create(:group) }

  let(:cache) { described_class.new }

  before do
    stub_feature_flags(granular_personal_access_tokens_enforcement_saas: enforced_group)
  end

  describe '#any_enforced?' do
    let(:ids) { [enforced_group.id, unenforced_group.id] }

    subject { cache.any_enforced?(ids) }

    context 'when a root namespace enforces granular tokens' do
      it { is_expected.to be(true) }
    end

    context 'when no root namespace enforces granular tokens' do
      let(:ids) { [unenforced_group.id] }

      it { is_expected.to be(false) }
    end

    context 'when the list is empty' do
      let(:ids) { [] }

      it { is_expected.to be(false) }
    end

    it 'does not run a query for namespaces already in the cache' do
      cache.any_enforced?(ids)

      expect { cache.any_enforced?(ids) }.not_to exceed_query_limit(0)
    end

    it 'avoids an N+1' do
      control = ActiveRecord::QueryRecorder.new { cache.any_enforced?([enforced_group.id]) }

      groups = create_list(:group, 3)

      expect { cache.any_enforced?(groups.map(&:id)) }.to issue_same_number_of_queries_as(control)
    end
  end
end
