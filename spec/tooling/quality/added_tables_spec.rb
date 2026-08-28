# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../tooling/quality/added_tables'

RSpec.describe Quality::AddedTables, feature_category: :tooling do
  subject(:added_tables) { described_class.new('abc123', repository_path: '/tmp') }

  def stub_git(output, success: true, base_ref_readable: true)
    readable = instance_double(Process::Status, success?: base_ref_readable)
    diff = instance_double(Process::Status, success?: success)

    allow(Open3).to receive(:capture2)
      .with('git', 'rev-parse', '--verify', '--quiet', 'abc123^{commit}', chdir: '/tmp')
      .and_return(['', readable])
    allow(Open3).to receive(:capture2)
      .with('git', 'diff', any_args)
      .and_return([output, diff])
  end

  describe '#entry_names' do
    it 'returns a name per added dictionary entry, FOSS and EE' do
      stub_git("db/docs/widgets.yml\nee/db/docs/premium_widgets.yml\n")

      expect(added_tables.entry_names).to eq(%w[widgets premium_widgets])
    end

    # Which of these names is a table is the dictionary's business, not git's, so entries from
    # other scopes are returned here and filtered by the caller.
    it 'returns names from other dictionary scopes too' do
      stub_git("db/docs/widgets.yml\ndb/docs/batched_background_migrations/BackfillWidgets.yml\n")

      expect(added_tables.entry_names).to eq(%w[widgets BackfillWidgets])
    end

    it 'ignores files that are not YAML' do
      stub_git("db/docs/widgets.yml\ndb/docs/README.md\n")

      expect(added_tables.entry_names).to eq(%w[widgets])
    end

    it 'is empty when the diff adds nothing' do
      stub_git("\n")

      expect(added_tables.entry_names).to be_empty
    end

    it 'is empty rather than raising when git fails' do
      stub_git('fatal: bad revision', success: false)

      expect(added_tables.entry_names).to be_empty
    end

    it 'asks git only for dictionary directories' do
      stub_git('')

      added_tables.entry_names

      expect(Open3).to have_received(:capture2)
        .with('git', 'diff', '--diff-filter=A', '--name-only', 'abc123...HEAD', '--', 'db/docs', 'ee/db/docs',
          chdir: '/tmp')
    end

    # A shallow CI clone may not contain the base ref. Returning an empty list there would be
    # indistinguishable from a diff that genuinely adds no tables, so it must raise instead.
    it 'raises when the base ref is not readable' do
      stub_git('', base_ref_readable: false)

      expect { added_tables.entry_names }.to raise_error(described_class::UnreadableBaseRef, /not readable/)
    end
  end
end
