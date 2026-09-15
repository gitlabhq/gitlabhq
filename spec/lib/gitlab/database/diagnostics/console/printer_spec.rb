# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console::Printer, feature_category: :database do
  let(:buffer) { StringIO.new }

  subject(:printer) { described_class.new(output: buffer) }

  before do
    Rainbow.enabled = false
  end

  def rendered
    buffer.string.split("\n")
  end

  describe '#status' do
    it 'renders the label, the summary and no severity as a clean line' do
      printer.status('main', 'OK', nil)

      expect(rendered).to eq(['main ... OK'])
    end

    it 'renders a summary for a severity' do
      printer.status('main', '1 error, 2 warnings', 'error')

      expect(rendered).to eq(['main ... 1 error, 2 warnings'])
    end
  end

  describe '#section' do
    it 'surrounds the title with blank lines' do
      printer.section('Search path')

      expect(buffer.string).to eq("\n== Search path ==\n\n")
    end
  end

  describe '#key_value' do
    it 'aligns values on the widest label' do
      printer.key_value('Current user', 'gitlab', label_width: 13)
      printer.key_value('Search path', 'public', label_width: 13)

      expect(rendered).to eq([
        '   Current user: gitlab',
        '   Search path:  public'
      ])
    end
  end

  describe '#finding' do
    it 'pads the tag to the widest severity so message bodies align' do
      printer.finding('error', 'Short message.')
      printer.finding('warning', 'Another message.')

      expect(rendered).to eq([
        '   [error]   Short message.',
        '   [warning] Another message.'
      ])
    end

    it 'wraps a long message under a hanging indent' do
      printer.finding('warning', 'word ' * 40)

      expect(rendered.first).to start_with('   [warning] word')
      expect(rendered.drop(1)).to all(start_with('             word'))
      expect(rendered.map(&:length)).to all(be <= described_class::WRAP_WIDTH)
    end

    it 'renders the tag alone for an empty message' do
      printer.finding('error', '')

      expect(rendered).to eq(['   [error]'])
    end
  end

  describe '#detail' do
    it 'indents and wraps the text' do
      printer.detail('a detail')

      expect(rendered).to eq(['   a detail'])
    end
  end

  describe '#table' do
    it 'pads every column to its widest cell and right-strips empty trailing cells' do
      printer.table(%w[SCHEMA OWNER CURRENT], [
        ['public', 'pg_database_owner', 'yes'],
        ['gitlab_partitions_static', 'gitlab', '']
      ])

      expect(rendered).to eq([
        '   SCHEMA                    OWNER              CURRENT',
        '   ------------------------  -----------------  -------',
        '   public                    pg_database_owner  yes',
        '   gitlab_partitions_static  gitlab'
      ])
    end

    it 'sizes columns from the headers when there are no rows' do
      printer.table(%w[SCHEMA OWNER], [])

      expect(rendered).to eq([
        '   SCHEMA  OWNER',
        '   ------  -----'
      ])
    end
  end

  describe 'colour' do
    around do |example|
      Rainbow.enabled = true
      example.run
    ensure
      Rainbow.enabled = false
    end

    it 'colours each severity and treats a clean status as green' do
      printer.status('main', 'OK', nil)
      printer.status('main', '1 error', 'error')
      printer.status('main', '1 warning', 'warning')

      expect(rendered[0]).to include(Rainbow('OK').green)
      expect(rendered[1]).to include(Rainbow('1 error').red)
      expect(rendered[2]).to include(Rainbow('1 warning').yellow)
    end
  end
end
