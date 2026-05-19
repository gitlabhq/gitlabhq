# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups_projects/_self_or_ancestor_transfer_notice.html.haml',
  feature_category: :groups_and_projects do
  let(:context) { build_stubbed(:group) }

  context 'when show_transfer_banner? is false' do
    before do
      allow(view).to receive(:show_transfer_banner?).with(context).and_return(false)
    end

    it 'does not rending anything' do
      output = view.render 'shared/groups_projects/self_or_ancestor_transfer_notice', context: context

      expect(output).to be_nil
    end
  end

  context 'when show_transfer_banner? is true' do
    before do
      allow(view).to receive(:show_transfer_banner?).with(context).and_return(true)
      allow(view).to receive(:transfer_banner_message).with(context).and_return('Transfer message')
    end

    it 'shows alert' do
      render 'shared/groups_projects/self_or_ancestor_transfer_notice', context: context

      expect(rendered).to have_css('.gl-alert-info')
      expect(rendered).to have_content('Transfer message')
    end
  end
end
