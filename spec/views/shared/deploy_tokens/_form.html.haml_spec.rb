# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/deploy_tokens/_form.html.haml' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:token) { build(:deploy_token) }

  RSpec.shared_examples "display deploy token settings" do |role, shows_package_registry_permissions|
    before do
      subject.add_user(user, role)
      allow(view).to receive(:current_user).and_return(user)
      stub_config(packages: { enabled: packages_enabled })
    end

    it "correctly renders the form" do
      render 'shared/deploy_tokens/form', token: token, group_or_project: subject

      if shows_package_registry_permissions
        expect(rendered).to have_content('Allows read access to the package registry')
      else
        expect(rendered).not_to have_content('Allows read access to the package registry')
      end
    end
  end

  context "when the subject is a project" do
    let_it_be(:subject, refind: true) { create(:project, :private) }

    where(:packages_enabled, :feature_enabled, :role, :shows_package_registry_permissions) do
      true  | true  | :maintainer | true
      false | true  | :maintainer | false
      true  | false | :maintainer | false
      false | false | :maintainer | false
    end

    with_them do
      before do
        subject.update!(packages_enabled: feature_enabled)
      end

      it_behaves_like 'display deploy token settings', params[:role], params[:shows_package_registry_permissions]
    end
  end

  context "when the subject is a group" do
    let_it_be(:subject, refind: true) { create(:group, :private) }

    where(:packages_enabled, :role, :shows_package_registry_permissions) do
      true  | :owner      | true
      false | :owner      | false
      true  | :maintainer | true
      false | :maintainer | false
    end

    with_them do
      it_behaves_like 'display deploy token settings', params[:role], params[:shows_package_registry_permissions]
    end
  end
end
