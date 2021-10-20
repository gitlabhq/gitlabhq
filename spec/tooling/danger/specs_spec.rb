# frozen_string_literal: true

require 'rspec-parameterized'
require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/specs'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Specs do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { double('fake-project-helper', helper: fake_helper).tap { |h| h.class.include(Tooling::Danger::ProjectHelper) } }
  let(:file_lines) do
    [
      " describe 'foo' do",
      " expect(foo).to match(['bar'])",
      " end",
      " expect(foo).to match(['bar'])", # same line as line 1 above, we expect two different suggestions
      " ",
      " expect(foo).to match ['bar']",
      " expect(foo).to eq(['bar'])",
      " expect(foo).to eq ['bar']",
      " expect(foo).to(match(['bar']))",
      " expect(foo).to(eq(['bar']))",
      " foo.eq(['bar'])"
    ]
  end

  let(:matching_lines) do
    [
      "+ expect(foo).to match(['bar'])",
      "+ expect(foo).to match(['bar'])",
      "+ expect(foo).to match ['bar']",
      "+ expect(foo).to eq(['bar'])",
      "+ expect(foo).to eq ['bar']",
      "+ expect(foo).to(match(['bar']))",
      "+ expect(foo).to(eq(['bar']))"
    ]
  end

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#add_suggestions_for_match_with_array' do
    let(:filename) { 'spec/foo_spec.rb' }

    before do
      expect(specs).to receive(:added_line_matching_match_with_array).and_return(matching_lines)
      allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
    end

    it 'adds suggestions at the correct lines' do
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to match_array(['bar'])"), file: filename, line: 2)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to match_array(['bar'])"), file: filename, line: 4)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to match_array ['bar']"), file: filename, line: 6)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to match_array(['bar'])"), file: filename, line: 7)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to match_array ['bar']"), file: filename, line: 8)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to(match_array(['bar']))"), file: filename, line: 9)
      expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT, suggested_line: " expect(foo).to(match_array(['bar']))"), file: filename, line: 10)

      specs.add_suggestions_for_match_with_array(filename)
    end
  end

  describe '#changed_specs_files' do
    let(:base_expected_files) { %w[spec/foo_spec.rb ee/spec/foo_spec.rb spec/bar_spec.rb ee/spec/bar_spec.rb spec/zab_spec.rb ee/spec/zab_spec.rb] }

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
        expect(specs.changed_specs_files(ee: :exclude)).not_to include(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end

    context 'with include_ee: :only' do
      it 'returns EE-specific spec files only' do
        expect(specs.changed_specs_files(ee: :only)).to match_array(%w[ee/spec/foo_spec.rb ee/spec/bar_spec.rb ee/spec/zab_spec.rb])
      end
    end
  end

  describe '#added_line_matching_match_with_array' do
    let(:filename) { 'spec/foo_spec.rb' }
    let(:changed_lines) do
      [
        "  expect(foo).to match(['bar'])",
        "  expect(foo).to match(['bar'])",
        "  expect(foo).to match ['bar']",
        "  expect(foo).to eq(['bar'])",
        "  expect(foo).to eq ['bar']",
        "- expect(foo).to match(['bar'])",
        "- expect(foo).to match(['bar'])",
        "- expect(foo).to match ['bar']",
        "- expect(foo).to eq(['bar'])",
        "- expect(foo).to eq ['bar']"
      ] + matching_lines
    end

    before do
      allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    end

    it 'returns added, modified, and renamed_after files by default' do
      expect(specs.added_line_matching_match_with_array(filename)).to match_array(matching_lines)
    end
  end
end
