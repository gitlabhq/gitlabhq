# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectHook, feature_category: :integrations do
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

  describe '#update_last_failure', :clean_gitlab_redis_shared_state do
    let(:hook) { build(:project_hook) }

    it 'is a method of this class' do
      expect { hook.update_last_failure }.not_to raise_error
    end

    context 'when the hook is executable' do
      it 'does not update the state' do
        expect(Gitlab::Redis::SharedState).not_to receive(:with)

        hook.update_last_failure
      end
    end

    context 'when the hook is failed' do
      before do
        allow(hook).to receive(:executable?).and_return(false)
      end

      def last_failure
        Gitlab::Redis::SharedState.with do |redis|
          redis.get("web_hooks:last_failure:project-#{hook.project.id}")
        end
      end

      context 'there is no prior value', :freeze_time do
        it 'updates the state' do
          expect { hook.update_last_failure }.to change { last_failure }.to(Time.current)
        end
      end

      context 'there is a prior value, from before now' do
        it 'updates the state' do
          the_future = 1.minute.from_now

          hook.update_last_failure

          travel_to(the_future) do
            expect { hook.update_last_failure }.to change { last_failure }.to(the_future.iso8601)
          end
        end
      end

      context 'there is a prior value, from after now' do
        it 'does not update the state' do
          the_past = 1.minute.ago

          hook.update_last_failure

          travel_to(the_past) do
            expect { hook.update_last_failure }.not_to change { last_failure }
          end
        end
      end
    end
  end
end
