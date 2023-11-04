# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/application' do
  context 'when user is signed in' do
    let(:user) { create(:user) }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
    end

    it_behaves_like 'a layout which reflects the application theme setting'
    it_behaves_like 'a layout which reflects the preferred language'

    describe "visual review toolbar" do
      context "ENV['REVIEW_APPS_ENABLED'] is set to true" do
        before do
          stub_env(
            'REVIEW_APPS_ENABLED' => true,
            'REVIEW_APPS_MERGE_REQUEST_IID' => '123'
          )
        end

        it 'renders the visual review toolbar' do
          render

          expect(rendered).to include('review-app-toolbar-script')
        end
      end

      context "ENV['REVIEW_APPS_ENABLED'] is set to false" do
        before do
          stub_env('REVIEW_APPS_ENABLED', false)
        end

        it 'does not render the visual review toolbar' do
          render

          expect(rendered).not_to include('review-app-toolbar-script')
        end
      end
    end

    context 'body data elements for pageview context' do
      let(:body_data) do
        {
          body_data_page: 'projects:issues:show',
          body_data_page_type_id: '1',
          body_data_project_id: '2',
          body_data_namespace_id: '3'
        }
      end

      before do
        allow(view).to receive(:body_data).and_return(body_data)
        render
      end

      it 'includes the body element page' do
        expect(rendered).to include('data-page="projects:issues:show"')
      end

      it 'includes the body element page_type_id' do
        expect(rendered).to include('data-page-type-id="1"')
      end

      it 'includes the body element project_id' do
        expect(rendered).to include('data-project-id="2"')
      end

      it 'includes the body element namespace_id' do
        expect(rendered).to include('data-namespace-id="3"')
      end
    end
  end

  context 'when user is not signed in' do
    before do
      allow(view).to receive(:current_user).and_return(nil)
      allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(nil))
    end

    it 'renders the new marketing header for logged-out users' do
      allow(view).to receive(:render)
      allow(view).to receive(:render).with({ template: "layouts/application" }, {}).and_call_original
      render
      expect(view).to have_received(:render).with({ partial: "layouts/header/super_sidebar_logged_out" })
    end
  end
end
