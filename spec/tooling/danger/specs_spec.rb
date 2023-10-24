# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/specs'

RSpec.describe Tooling::Danger::Specs, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:filename) { 'spec/foo_spec.rb' }

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  describe '#changed_specs_files' do
    let(:base_expected_files) do
      %w[
        spec/foo_spec.rb ee/spec/foo_spec.rb spec/bar_spec.rb
        ee/spec/bar_spec.rb spec/zab_spec.rb ee/spec/zab_spec.rb
      ]
    end

    before do
      all_changed_files = %w[
        app/workers/a.rb
        app/workers/b.rb
        app/workers/e.rb
        spec/foo_spec.rb
        ee/spec/foo_spec.rb
        spec/bar_spec.rb
        ee/spec/bar_spec.rb
        spec/zab_spec.rb
        ee/spec/zab_spec.rb
      ]

      allow(specs.helper).to receive(:all_changed_files).and_return(all_changed_files)
    end

    it 'returns added, modified, and renamed_after files by default' do
      expect(specs.changed_specs_files).to match_array(base_expected_files)
    end

    context 'with include_ee: :exclude' do
      it 'returns spec files without EE-specific files' do
        expect(specs.changed_specs_files(ee: :exclude))
          .not_to include(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end

    context 'with include_ee: :only' do
      it 'returns EE-specific spec files only' do
        expect(specs.changed_specs_files(ee: :only))
          .to match_array(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end
  end
end
