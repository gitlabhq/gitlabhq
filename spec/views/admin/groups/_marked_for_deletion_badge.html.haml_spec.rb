# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/groups/_marked_for_deletion_badge.html.haml', feature_category: :groups_and_projects do
  let(:group) { build(:group) }

  before do
    allow(group).to receive(:marked_for_deletion?).and_return(marked_for_deletion)

    render 'admin/groups/marked_for_deletion_badge', group: group
  end

  context 'when the group is not marked for deletion' do
    let(:marked_for_deletion) { false }

    it 'does not render the badge' do
      expect(rendered).not_to have_css('.badge-warning')
    end
  end

  context 'when the group is marked for deletion' do
    let(:marked_for_deletion) { true }

    it 'renders the badge' do
      expect(rendered).to have_css('.badge-warning', text: 'Pending deletion')
    end
  end
end
