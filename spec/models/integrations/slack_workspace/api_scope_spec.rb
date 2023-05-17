# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackWorkspace::ApiScope, feature_category: :integrations do
  describe '.find_or_initialize_by_names' do
    it 'acts as insert into a global set of scope names' do
      expect { described_class.find_or_initialize_by_names(%w[foo bar baz]) }
        .to change { described_class.count }.by(3)

      expect { described_class.find_or_initialize_by_names(%w[bar baz foo buzz]) }
        .to change { described_class.count }.by(1)

      expect { described_class.find_or_initialize_by_names(%w[baz foo]) }
        .to change { described_class.count }.by(0)

      expect(described_class.pluck(:name)).to match_array(%w[foo bar baz buzz])
    end
  end
end
