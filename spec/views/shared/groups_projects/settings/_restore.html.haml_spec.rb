# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups_projects/settings/_restore.html.haml', feature_category: :groups_and_projects do
  let(:context) { build_stubbed(:group) }

  before do
    allow(view).to receive_messages(
      restore_namespace_title: 'Restore group',
      restore_namespace_scheduled_for_deletion_message: 'This group will be restored.',
      restore_namespace_path: '/restore/path'
    )
  end

  context 'when context is not scheduled for deletion' do
    before do
      allow(context).to receive(:self_deletion_scheduled?).and_return(false)
    end

    it 'renders nothing' do
      output = view.render 'shared/groups_projects/settings/restore', context: context,
        tracking_event: 'trigger_restore_on_group'

      expect(output).to be_nil
    end
  end

  context 'when context is scheduled for deletion' do
    before do
      allow(context).to receive(:self_deletion_scheduled?).and_return(true)
    end

    it 'assigns the tracking items' do
      render 'shared/groups_projects/settings/restore', context: context, tracking_event: 'trigger_restore_on_group'

      expect(rendered).to trigger_internal_events('trigger_restore_on_group').on_click
        .with(additional_properties: { label: 'setting' })
    end
  end
end
