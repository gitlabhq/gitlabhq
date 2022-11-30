# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHook do
  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:integration) }
  end

  describe 'executable?' do
    let!(:hooks) do
      [
        [0, Time.current],
        [0, 1.minute.from_now],
        [1, 1.minute.from_now],
        [3, 1.minute.from_now],
        [4, nil],
        [4, 1.day.ago],
        [4, 1.minute.from_now],
        [0, nil],
        [0, 1.day.ago],
        [1, nil],
        [1, 1.day.ago],
        [3, nil],
        [3, 1.day.ago]
      ].map do |(recent_failures, disabled_until)|
        create(:service_hook, recent_failures: recent_failures, disabled_until: disabled_until)
      end
    end

    it 'is always true' do
      expect(hooks).to all(be_executable)
    end
  end

  describe 'execute' do
    let(:hook) { build(:service_hook) }
    let(:data) { { key: 'value' } }

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, 'service_hook', force: false).and_call_original
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data)
    end
  end

  describe '#parent' do
    let(:hook) { build(:service_hook, integration: integration) }

    context 'with a project-level integration' do
      let(:project) { build(:project) }
      let(:integration) { build(:integration, project: project) }

      it 'returns the associated project' do
        expect(hook.parent).to eq(project)
      end
    end

    context 'with a group-level integration' do
      let(:group) { build(:group) }
      let(:integration) { build(:integration, :group, group: group) }

      it 'returns the associated group' do
        expect(hook.parent).to eq(group)
      end
    end

    context 'with an instance-level integration' do
      let(:integration) { build(:integration, :instance) }

      it 'returns nil' do
        expect(hook.parent).to be_nil
      end
    end
  end

  describe '#application_context' do
    let(:hook) { build(:service_hook) }

    it 'includes the type' do
      expect(hook.application_context).to eq(
        related_class: 'ServiceHook'
      )
    end
  end
end
