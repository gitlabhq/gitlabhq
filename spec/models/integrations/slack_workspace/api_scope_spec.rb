# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackWorkspace::ApiScope, feature_category: :integrations do
  describe '.find_or_initialize_by_names' do
    let_it_be(:organization) { create(:organization) }

    it 'acts as insert into a global set of scope names' do
      expect { described_class.find_or_initialize_by_names(%w[foo bar baz], organization_id: organization.id) }
        .to change { described_class.count }.by(3)

      expect { described_class.find_or_initialize_by_names(%w[bar baz foo buzz], organization_id: organization.id) }
        .to change { described_class.count }.by(1)

      expect { described_class.find_or_initialize_by_names(%w[baz foo], organization_id: organization.id) }
        .not_to change { described_class.count }

      expect(described_class.pluck(:name)).to match_array(%w[foo bar baz buzz])
    end
  end
end
