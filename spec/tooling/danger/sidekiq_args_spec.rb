# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/sidekiq_args'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::SidekiqArgs, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { Tooling::Danger::ProjectHelper }

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#args_changed?' do
    using RSpec::Parameterized::TableSyntax

    where(:before, :after, :result) do
      " - def perform"           | " + def perform(abc)"           | true
      " -   def perform"         | " +           def perform(abc)" | true
      " - def perform(abc)"      | " + def perform(def)"           | true
      " - def perform(abc, def)" | " + def perform(abc)"           | true
      " - def perform(abc, def)" | " + def perform(def, abc)"      | true
      " - def perform"           | " - def perform"                | false
      " + def perform"           | " + def perform"                | false
      " - def perform(abc)"      | " - def perform(abc)"           | false
      " + def perform(abc)"      | " + def perform(abc)"           | false
      " - def perform(abc)"      | " + def perform_foo(abc)"       | false
    end

    with_them do
      it 'returns correct result' do
        expect(specs.args_changed?([before, after])).to eq(result)
      end
    end
  end

  describe '#add_comment_for_matched_line' do
    let(:filename) { 'app/workers/hello_worker.rb' }
    let(:file_lines) do
      [
        "Module Worker",
        " def perform",
        "  puts hello world",
        " end",
        "end"
      ]
    end

    before do
      allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
    end

    context 'when args are changed' do
      before do
        allow(specs.helper).to receive(:changed_lines).and_return([" - def perform", " + def perform(abc)"])
        allow(specs).to receive(:args_changed?).and_return(true)
      end

      it 'adds suggestion at the correct lines' do
        expect(specs).to receive(:markdown).with(format(described_class::SUGGEST_MR_COMMENT), file: filename, line: 2)

        specs.add_comment_for_matched_line(filename)
      end

      it 'adds a top level warning' do
        allow(specs).to receive(:markdown)
        expect(specs).to receive(:warn).with(described_class::MR_WARNING_COMMENT)

        specs.add_comment_for_matched_line(filename)
      end
    end

    context 'when args are not changed' do
      before do
        allow(specs.helper).to receive(:changed_lines).and_return([" - def perform", " - def perform"])
        allow(specs).to receive(:args_changed?).and_return(false)
      end

      it 'does not add suggestion' do
        expect(specs).not_to receive(:markdown)

        specs.add_comment_for_matched_line(filename)
      end

      it 'does not add a top level warning' do
        expect(specs).not_to receive(:warn)

        specs.add_comment_for_matched_line(filename)
      end
    end
  end

  describe '#changed_worker_files' do
    let(:base_expected_files) { %w[app/workers/a.rb app/workers/b.rb ee/app/workers/e.rb] }

    before do
      all_changed_files = %w[
        app/workers/a.rb
        app/workers/b.rb
        ee/app/workers/e.rb
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
      expect(specs.changed_worker_files).to match_array(base_expected_files)
    end

    context 'with include_ee: :exclude' do
      it 'returns spec files without EE-specific files' do
        expect(specs.changed_worker_files(ee: :exclude)).not_to include(%w[ee/app/workers/e.rb])
      end
    end

    context 'with include_ee: :only' do
      it 'returns EE-specific spec files only' do
        expect(specs.changed_worker_files(ee: :only)).to match_array(%w[ee/app/workers/e.rb])
      end
    end
  end
end
