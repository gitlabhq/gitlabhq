# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectHook do
  describe 'associations' do
    it { is_expected.to belong_to :project }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:project_hook, project: create(:project)) }
  end

  describe '.push_hooks' do
    it 'returns hooks for push events only' do
      hook = create(:project_hook, push_events: true)
      create(:project_hook, push_events: false)
      expect(described_class.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'returns hooks for tag push events only' do
      hook = create(:project_hook, tag_push_events: true)
      create(:project_hook, tag_push_events: false)
      expect(described_class.tag_push_hooks).to eq([hook])
    end
  end

  describe '#rate_limit' do
    let_it_be(:hook) { create(:project_hook) }
    let_it_be(:plan_limits) { create(:plan_limits, :default_plan, web_hook_calls: 100) }

    it 'returns the default limit' do
      expect(hook.rate_limit).to be(100)
    end
  end

  describe '#application_context' do
    let_it_be(:hook) { build(:project_hook) }

    it 'includes the type and project' do
      expect(hook.application_context).to include(
        related_class: 'ProjectHook',
        project: hook.project
      )
    end
  end
end
