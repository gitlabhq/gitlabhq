# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackWorkspace::ApiScope, feature_category: :integrations do
  let_it_be(:organization) { create(:organization) }

  describe '.find_or_initialize_by_names' do
    it 'acts as insert into a global set of scope names' do
      expect { described_class.find_or_initialize_by_names(%w[foo bar baz], organization_id: organization.id) }
        .to change { described_class.count }.by(3)

      expect { described_class.find_or_initialize_by_names(%w[bar baz foo buzz], organization_id: organization.id) }
        .to change { described_class.count }.by(1)

      expect { described_class.find_or_initialize_by_names(%w[baz foo], organization_id: organization.id) }
        .not_to change { described_class.count }

      expect(described_class.pluck(:name)).to match_array(%w[foo bar baz buzz])
    end

    it 'prevents race conditions when inserting' do
      expect do
        described_class.find_or_initialize_by_names(%w[foo bar baz], organization_id: organization.id)
      end.to make_queries_matching(/ON CONFLICT\s+DO NOTHING/)
    end
  end

  describe 'find_or_initialize_by_names_and_organizations' do
    let_it_be(:organization2) { create(:organization) }

    subject(:scopes_by_organization) do
      described_class.find_or_initialize_by_names_and_organizations(
        %w[foo bar],
        [organization.id, organization2.id]
      )
    end

    it 'creates the necessary scopes in each organization', :aggregate_failures do
      expect do
        scopes_by_organization
      end.to change { described_class.count }.by(4)

      expect(scopes_by_organization).to match(
        organization.id => contain_exactly(
          have_attributes(name: 'foo', organization_id: organization.id),
          have_attributes(name: 'bar', organization_id: organization.id)
        ),
        organization2.id => contain_exactly(
          have_attributes(name: 'foo', organization_id: organization2.id),
          have_attributes(name: 'bar', organization_id: organization2.id)
        )
      )
    end
  end
end
