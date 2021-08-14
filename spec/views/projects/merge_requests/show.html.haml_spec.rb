# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/show.html.haml', :aggregate_failures do
  using RSpec::Parameterized::TableSyntax

  include_context 'merge request show action'

  before do
    merge_request.reload
  end

  context 'when the merge request is open' do
    it 'shows the "Mark as draft" button' do
      render

      expect(rendered).to have_css('a', visible: true, text: 'Mark as draft')
      expect(rendered).to have_css('a', visible: false, text: 'Reopen')
      expect(rendered).to have_css('a', visible: true, text: 'Close')
    end
  end

  context 'when the merge request is closed' do
    before do
      merge_request.close!
    end

    it 'shows the "Reopen" button' do
      render

      expect(rendered).not_to have_css('a', visible: true, text: 'Mark as draft')
      expect(rendered).to have_css('a', visible: true, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end

    context 'when source project does not exist' do
      it 'does not show the "Reopen" button' do
        allow(merge_request).to receive(:source_project).and_return(nil)

        render

        expect(rendered).to have_css('a', visible: false, text: 'Reopen')
        expect(rendered).to have_css('a', visible: false, text: 'Close')
      end
    end
  end

  describe 'gitpod modal' do
    let(:gitpod_modal_selector) { '#modal-enable-gitpod' }
    let(:user) { create(:user) }
    let(:user_gitpod_enabled) { create(:user).tap { |x| x.update!(gitpod_enabled: true) } }

    where(:site_enabled, :current_user, :should_show) do
      false | ref(:user) | false
      true  | ref(:user) | true
      true  | nil | true
      true  | ref(:user_gitpod_enabled) | false
    end

    with_them do
      it 'handles rendering gitpod user enable modal' do
        allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(site_enabled)
        allow(view).to receive(:current_user).and_return(current_user)

        render

        if should_show
          expect(rendered).to have_css(gitpod_modal_selector)
        else
          expect(rendered).to have_no_css(gitpod_modal_selector)
        end
      end
    end
  end
end
