# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/approval'
require 'gitlab/dangerfiles/spec_helper'

RSpec.describe 'Reviewer roulette label resolution', feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_helper) { Danger::Helper.new(fake_danger.new) }

  before do
    fake_helper.config do |config|
      config.custom_labels_for_categories = {
        'merge requests backend': '~"Merge Requests backend"',
        geo: '~"group::geo"'
      }
    end

    # In a real Danger run a plugin's #helper accessor resolves back to the
    # Danger::Helper instance; that wiring is absent in this isolated unit.
    allow(fake_helper).to receive(:helper).and_return(fake_helper)
  end

  describe 'Danger::Helper#label_for_category' do
    using RSpec::Parameterized::TableSyntax

    where(:category, :expected_label) do
      :geo                      | '~"group::geo"'
      :'merge requests backend' | '~"Merge Requests backend"'
      :docs                     | '~documentation'
      :unknown_category         | '~"unknown_category"'
    end

    with_them do
      it 'returns the expected label reference' do
        expect(fake_helper.label_for_category(category)).to eq(expected_label)
      end
    end
  end

  describe 'CODEOWNERS section to category derivation' do
    # Guards the assumption behind the geo mapping: a CODEOWNERS section named
    # "Geo" reaches label_for_category as the downcased symbol :geo. If the gem
    # stops downcasing, the mapping would break silently, so pin it here.
    it 'downcases a non-codeowners section name into a symbol' do
      rule = { 'section' => 'Geo', 'name' => 'Geo' }

      approval = Gitlab::Dangerfiles::Approval.from_approval_rule(rule, nil)

      expect(approval.category).to eq(:geo)
    end
  end
end
