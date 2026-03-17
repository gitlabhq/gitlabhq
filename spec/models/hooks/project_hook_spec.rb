# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectHook, feature_category: :webhooks do
  include_examples 'a hook that gets automatically disabled on failure' do
    let_it_be(:project) { create(:project) }

    let(:hook) { build(:project_hook, project: project) }
    let(:hook_factory) { :project_hook }
    let(:default_factory_arguments) { { project: project } }

    def find_hooks
      project.hooks
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_many(:web_hook_logs) }
  end

  describe '#destroy' do
    it 'does not cascade to web_hook_logs' do
      web_hook = create(:project_hook)
      create_list(:web_hook_log, 3, web_hook: web_hook)

      expect { web_hook.destroy! }.not_to change { web_hook.web_hook_logs.count }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:project_hook) }
  end

  describe '.for_projects' do
    it 'finds related project hooks' do
      hook_a = create(:project_hook, project: build(:project))
      hook_b = create(:project_hook, project: build(:project))
      hook_c = create(:project_hook, project: build(:project))

      expect(described_class.for_projects([hook_a.project, hook_b.project]))
        .to contain_exactly(hook_a, hook_b)
      expect(described_class.for_projects(hook_c.project))
        .to contain_exactly(hook_c)
    end
  end

  describe '.push_hooks' do
    it 'returns hooks for push events only' do
      project = build(:project)
      hook = create(:project_hook, project: project, push_events: true)
      create(:project_hook, project: project, push_events: false)
      expect(described_class.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'returns hooks for tag push events only' do
      project = build(:project)
      hook = create(:project_hook, project: project, tag_push_events: true)
      create(:project_hook, project: project, tag_push_events: false)
      expect(described_class.tag_push_hooks).to eq([hook])
    end
  end

  describe '#parent' do
    it 'returns the associated project' do
      project = build(:project)
      hook = build(:project_hook, project: project)

      expect(hook.parent).to eq(project)
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

  describe '.available_hooks' do
    context 'without EE license', unless: Gitlab.ee? do
      it 'returns all available hooks' do
        expect(described_class.available_hooks).to match_array(described_class::AVAILABLE_HOOKS)
      end
    end

    context 'with EE license', if: Gitlab.ee? do
      it 'returns all available hooks, including EE hooks' do
        expect(described_class.available_hooks).to match_array(
          described_class::AVAILABLE_HOOKS + EE::ProjectHook::EE_AVAILABLE_HOOKS)
      end
    end
  end
end
