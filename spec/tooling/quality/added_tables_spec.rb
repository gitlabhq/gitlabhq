# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'

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

    it 'returns a name once when the same entry is added to both dictionary roots' do
      stub_git("db/docs/widgets.yml\nee/db/docs/widgets.yml\n")

      expect(added_tables.entry_names).to eq(%w[widgets])
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

    it 'asks git only for the dictionary roots' do
      stub_git('')

      added_tables.entry_names

      expect(Open3).to have_received(:capture2)
        .with('git', 'diff', '--diff-filter=A', '--name-only', 'abc123...HEAD', '--',
          ':(glob)db/docs/*.yml', ':(glob)ee/db/docs/*.yml', chdir: '/tmp')
    end

    # A shallow CI clone may not contain the base ref. Returning an empty list there would be
    # indistinguishable from a diff that genuinely adds no tables, so it must raise instead.
    it 'raises when the base ref is not readable' do
      stub_git('', base_ref_readable: false)

      expect { added_tables.entry_names }.to raise_error(described_class::UnreadableBaseRef, /not readable/)
    end
  end

  # The stubs above assert the arguments; only a real repository proves what git does with them.
  describe '#entry_names against a real repository' do
    let(:repository_path) { Dir.mktmpdir }
    let(:base_ref) { git('rev-parse', 'HEAD').strip }

    before do
      git('init', '--quiet', '--initial-branch', 'main', '.')
      git('config', 'user.email', 'spec@example.com')
      git('config', 'user.name', 'Spec')
      write('db/docs/existing_table.yml')
      commit('base')
    end

    after do
      FileUtils.remove_entry(repository_path)
    end

    def git(*arguments)
      Open3.capture2('git', *arguments, chdir: repository_path).first
    end

    def write(relative_path)
      absolute = File.join(repository_path, relative_path)
      FileUtils.mkdir_p(File.dirname(absolute))
      File.write(absolute, "---\n")
    end

    def commit(message)
      git('add', '--all')
      git('commit', '--quiet', '--no-gpg-sign', '--message', message)
    end

    def entry_names
      described_class.new(base_ref, repository_path: repository_path).entry_names
    end

    it 'names an entry added to a dictionary root' do
      base_ref
      write('db/docs/new_table.yml')
      write('ee/db/docs/new_premium_table.yml')
      commit('add entries')

      expect(entry_names).to contain_exactly('new_table', 'new_premium_table')
    end

    # The regression: these files are named after the table they describe, so a name escaping
    # from here resolves to that real table and the caller reports it as newly added.
    it 'names nothing for a file added under a dictionary sub-directory' do
      base_ref
      write('db/docs/data_retention/existing_table.yml')
      write('db/docs/views/some_view.yml')
      write('ee/db/docs/data_retention/existing_table.yml')
      commit('add a retention policy')

      expect(entry_names).to be_empty
    end
  end
end
