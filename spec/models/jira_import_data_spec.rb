# frozen_string_literal: true

require 'spec_helper'

describe JiraImportData do
  let(:symbol_keys_project) do
    { key: 'AA', scheduled_at: 2.days.ago.strftime('%Y-%m-%d %H:%M:%S'), scheduled_by: { 'user_id' => 1, 'name' => 'tester1' } }
  end

  let(:string_keys_project) do
    { 'key': 'BB', 'scheduled_at': 1.hour.ago.strftime('%Y-%m-%d %H:%M:%S'), 'scheduled_by': { 'user_id': 2, 'name': 'tester2' } }
  end

  let(:jira_project_details) do
    JiraImportData::JiraProjectDetails.new('CC', 1.day.ago.strftime('%Y-%m-%d %H:%M:%S'), { user_id: 3, name: 'tester3' })
  end

  describe '#projects' do
    it 'returns empty array if no data' do
      expect(described_class.new.projects).to eq([])
    end

    it 'returns empty array if no projects' do
      import_data = described_class.new(data: { 'some-key' => 10 })
      expect(import_data.projects).to eq([])
    end

    it 'returns JiraProjectDetails sorted by scheduled_at time' do
      import_data = described_class.new(data: { jira: { projects: [symbol_keys_project, string_keys_project, jira_project_details] } })

      expect(import_data.projects.size).to eq 3
      expect(import_data.projects.map(&:key)).to eq(%w(AA CC BB))
      expect(import_data.projects.map(&:scheduled_by).map {|e| e['name']}).to eq %w(tester1 tester3 tester2)
      expect(import_data.projects.map(&:scheduled_by).map {|e| e['user_id']}).to eq [1, 3, 2]
    end
  end

  describe 'add projects' do
    it 'adds project when data is nil' do
      import_data = described_class.new
      expect(import_data.data).to be nil

      import_data << string_keys_project

      expect(import_data.data).to eq({ 'jira' => { 'projects' => [string_keys_project] } })
    end

    it 'adds project when data has some random info' do
      import_data = described_class.new(data: { 'one-key': 10 })
      expect(import_data.data).to eq({ 'one-key' => 10 })

      import_data << string_keys_project

      expect(import_data.data).to eq({ 'one-key' => 10, 'jira' => { 'projects' => [string_keys_project] } })
    end

    it 'adds project when data already has some jira projects' do
      import_data = described_class.new(data: { jira: { projects: [symbol_keys_project] } })
      expect(import_data.projects.map(&:to_h)).to eq [symbol_keys_project]

      import_data << string_keys_project

      expect(import_data.data['jira']['projects'].size).to eq 2
      expect(import_data.projects.map(&:key)).to eq(%w(AA BB))
      expect(import_data.projects.map(&:scheduled_by).map {|e| e['name']}).to eq %w(tester1 tester2)
      expect(import_data.projects.map(&:scheduled_by).map {|e| e['user_id']}).to eq [1, 2]
    end
  end

  describe '#force_import!' do
    it 'sets force import when data is nil' do
      import_data = described_class.new

      import_data.force_import!

      expect(import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be true
      expect(import_data.force_import?).to be false
    end

    it 'sets force import when data is present but no jira key' do
      import_data = described_class.new(data: { 'some-key': 'some-data' })

      import_data.force_import!

      expect(import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be true
      expect(import_data.data).to eq({ 'some-key' => 'some-data', 'jira' => { JiraImportData::FORCE_IMPORT_KEY => true } })
      expect(import_data.force_import?).to be false
    end

    it 'sets force import when data and jira keys exist' do
      import_data = described_class.new(data: { 'some-key': 'some-data', 'jira': {} })

      import_data.force_import!

      expect(import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be true
      expect(import_data.data).to eq({ 'some-key' => 'some-data', 'jira' => { JiraImportData::FORCE_IMPORT_KEY => true } })
      expect(import_data.force_import?).to be false
    end

    it 'sets force import when data and jira project data exist' do
      import_data = described_class.new(data: { jira: { projects: [symbol_keys_project], JiraImportData::FORCE_IMPORT_KEY => false }, 'some-key': 'some-data' })

      import_data.force_import!

      expect(import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be true
      expect(import_data.data).to eq({ 'some-key' => 'some-data', 'jira' => { 'projects' => [symbol_keys_project.deep_stringify_keys!], JiraImportData::FORCE_IMPORT_KEY => true } })
      expect(import_data.force_import?).to be true
    end
  end

  describe '#force_import?' do
    it 'returns false when data blank' do
      expect(described_class.new.force_import?).to be false
    end

    it 'returns false if there is no project data present' do
      import_data = described_class.new(data: { jira: { JiraImportData::FORCE_IMPORT_KEY => true }, 'one-key': 10 })

      expect(import_data.force_import?).to be false
    end

    it 'returns false when force import set to false' do
      import_data = described_class.new(data: { jira: { projects: [symbol_keys_project], JiraImportData::FORCE_IMPORT_KEY => false }, 'one-key': 10 })

      expect(import_data.force_import?).to be false
    end

    it 'returns true when force import set to true' do
      import_data = described_class.new(data: { jira: { projects: [symbol_keys_project], JiraImportData::FORCE_IMPORT_KEY => true } })

      expect(import_data.force_import?).to be true
    end
  end
end
