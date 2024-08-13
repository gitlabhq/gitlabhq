# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'

require_relative '../../../tooling/danger/settings_sections'

RSpec.describe Tooling::Danger::SettingsSections, feature_category: :tooling do
  include_context 'with dangerfile'

  subject(:settings_section_check) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:matching_changed_files) { ['app/views/foo/bar.html.haml', 'app/assets/js/foo/bar.vue'] }
  let(:changed_lines) { ['-render SettingsBlockComponent.new(id: "foo") do', '<settings-section id="foo">'] }
  let(:stable_branch?) { false }

  before do
    allow(fake_helper).to receive(:changed_files).and_return(matching_changed_files)
    allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
    allow(fake_helper).to receive(:stable_branch?).and_return(stable_branch?)
  end

  context 'when on stable branch' do
    let(:stable_branch?) { true }

    it 'does not write any markdown' do
      expect(settings_section_check).not_to receive(:markdown)
      settings_section_check.check!
    end
  end

  context 'when none of the changed files are Haml or Vue files' do
    let(:matching_changed_files) { [] }

    it 'does not write any markdown' do
      expect(settings_section_check).not_to receive(:markdown)
      settings_section_check.check!
    end
  end

  context 'when none of the changed lines match the pattern' do
    let(:changed_lines) { ['-foo', '+bar'] }

    it 'does not write any markdown' do
      expect(settings_section_check).not_to receive(:markdown)
      settings_section_check.check!
    end
  end

  context 'when some files match the pattern but in ignored folders' do
    let(:matching_changed_files) { ['app/views/admin/foo/bar.html.haml', 'ee/app/views/profiles/foo/bar.html.haml'] }

    it 'does not write any markdown' do
      expect(settings_section_check).not_to receive(:markdown)
      settings_section_check.check!
    end
  end

  it 'adds a new markdown section listing every matching line' do
    expect(settings_section_check).to receive(:markdown).with(/Searchable setting sections/)
    expect(settings_section_check).to receive(:markdown).with(/SettingsBlock/)
    expect(settings_section_check).to receive(:markdown).with(/settings-section/)
    settings_section_check.check!
  end
end
