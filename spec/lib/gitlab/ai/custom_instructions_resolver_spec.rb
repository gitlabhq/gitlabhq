# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ai::CustomInstructionsResolver, feature_category: :ai_abstraction_layer do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- ancestor traversal and settings need persisted records
  let_it_be(:top_group, freeze: false) { create(:group, name: 'top') }
  let(:top_text) { nil }
  let(:sub_text) { nil }
  let_it_be(:sub_group, freeze: false) { create(:group, name: 'sub', parent: top_group) }
  let_it_be(:project, freeze: false) { create(:project, group: sub_group) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  subject(:entries) { described_class.new(resource.class.find(resource.id)).resolve }

  before do
    set_group_instructions(top_group, top_text)
    set_group_instructions(sub_group, sub_text)
  end

  def set_group_instructions(group, text)
    setting = NamespaceSetting.find_or_create_by!(namespace_id: group.id)
    setting.update!(ai_custom_instructions: text)
  end

  context 'for a project whose ancestor groups are all set' do
    let(:resource) { project }
    let(:top_text) { 'top group rule' }
    let(:sub_text) { 'sub group rule' }

    it 'concatenates the group chain, most general first and most specific last' do
      expect(entries).to eq([
        ["Group: #{top_group.full_path}", 'top group rule'],
        ["Group: #{sub_group.full_path}", 'sub group rule']
      ])
    end
  end

  context 'when some group levels are blank' do
    let(:resource) { project }
    let(:top_text) { 'top group rule' }
    let(:sub_text) { '   ' }

    it 'skips blank levels' do
      expect(entries).to eq([
        ["Group: #{top_group.full_path}", 'top group rule']
      ])
    end
  end

  context 'for a group resource' do
    let(:resource) { sub_group }
    let(:top_text) { 'top group rule' }
    let(:sub_text) { 'sub group rule' }

    it 'includes the group and its ancestor chain' do
      expect(entries).to eq([
        ["Group: #{top_group.full_path}", 'top group rule'],
        ["Group: #{sub_group.full_path}", 'sub group rule']
      ])
    end
  end

  context 'for a project in a user namespace (no group)' do
    let_it_be(:user_project, freeze: false) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs a persisted project without a group
    let(:resource) { user_project }

    it 'returns no entries without raising' do
      expect(entries).to be_empty
    end
  end

  context 'when nothing is set' do
    let(:resource) { project }

    it 'returns no entries' do
      expect(entries).to be_empty
    end
  end

  context 'when a level has surrounding whitespace' do
    let(:resource) { sub_group }
    let(:sub_text) { "  padded sub group  " }

    it 'strips surrounding whitespace from each level' do
      expect(entries).to include(["Group: #{sub_group.full_path}", 'padded sub group'])
    end
  end

  describe 'query count' do
    let(:resource) { project }
    let(:top_text) { 'top group rule' }
    let(:sub_text) { 'sub group rule' }

    it 'does not issue queries per ancestor' do
      # `full_path` reads `route` and `ai_custom_instructions` delegates to
      # `namespace_settings`, so both must be preloaded or the block runs on
      # every group and project page render at 1 + 2N queries.
      recorder = ActiveRecord::QueryRecorder.new { entries }

      expect(recorder.log.grep(/FROM "namespace_settings"/).size).to eq(1)
      expect(recorder.log.grep(/FROM "routes"/).size).to eq(1)
    end
  end
end
