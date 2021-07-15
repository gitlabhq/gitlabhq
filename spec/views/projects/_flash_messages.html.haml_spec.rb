# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_flash_messages' do
  let_it_be(:template) { 'projects/flash_messages' }
  let_it_be(:user) { create(:user) }

  let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
  let_it_be(:html) { create(:programming_language, name: 'HTML') }
  let_it_be(:hcl) { create(:programming_language, name: 'HCL') }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).with(user, :download_code, project).and_return(true)
  end

  context 'when current_user has download_code permission' do
    context 'when user has a terraform state' do
      let_it_be(:project) { create(:project) }
      let_it_be(:terraform_state) { create(:terraform_state, :locked, :with_version, project: project) }

      it "doesn't show the terraform notification banner" do
        render(template, project: project)
        expect(view.content_for(:flash_message)).not_to have_selector('.js-terraform-notification')
      end
    end

    context 'when there are no .tf files in the repository' do
      let_it_be(:project) { create(:project) }
      let_it_be(:mock_repo_languages) do
        { project => { ruby => 0.5, html => 0.5 } }
      end

      before do
        mock_repo_languages.each do |project, lang_shares|
          lang_shares.each do |lang, share|
            create(:repository_language, project: project, programming_language: lang, share: share)
          end
        end
      end

      it "doesn't show the terraform notification banner" do
        render(template, project: project)
        expect(view.content_for(:flash_message)).not_to have_selector('.js-terraform-notification')
      end
    end

    context 'when .tf files are present in the repository and user does not have any terraform states' do
      let_it_be(:project) { create(:project) }
      let_it_be(:mock_repo_languages) do
        { project => { ruby => 0.5, hcl => 0.5 } }
      end

      before do
        mock_repo_languages.each do |project, lang_shares|
          lang_shares.each do |lang, share|
            create(:repository_language, project: project, programming_language: lang, share: share)
          end
        end
      end

      it 'shows the terraform notification banner' do
        render(template, project: project)
        expect(view.content_for(:flash_message)).to have_selector('.js-terraform-notification')
      end
    end
  end
end
