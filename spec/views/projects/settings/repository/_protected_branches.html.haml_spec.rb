# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/repository/_protected_branches', feature_category: :source_code_management do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:branch) { build(:protected_branch) }

  before do
    assign :project, project
    assign :protected_branch, branch
    assign :protected_branches, [branch]

    allow(view).to receive(:current_user) { user }
    allow(view).to receive(:protected_branch_entity) { project }
    allow(view).to receive(:project_protected_branch_path).and_return('http://protected-branch-url.com')
    allow(view).to receive(:paginate).and_return('')
  end

  context 'when a user has admin_protected_branch allowed' do
    before do
      allow(view).to receive(:can?).with(user, :admin_protected_branch, project).and_return(true)
    end

    it 'renders the section titles' do
      render

      aggregate_failures do
        expect(rendered).to have_text('Protected branches')
        expect(rendered).to have_text(branch.name)
        expect(rendered).to have_button('Add protected branch')
        expect(rendered).to have_link('Unprotect')
      end
    end
  end

  context 'when a user does not have admin_protected_branch allowed' do
    before do
      allow(view).to receive(:can?).with(user, :admin_protected_branch, project).and_return(false)
    end

    it 'does not render the section titles' do
      render

      aggregate_failures do
        expect(rendered).not_to have_text('Protected branches')
        expect(rendered).not_to have_text(branch.name)
        expect(rendered).not_to have_button('Add protected branch')
        expect(rendered).not_to have_link('Unprotect')
      end
    end
  end
end
