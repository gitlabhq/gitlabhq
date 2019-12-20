# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/header/_new_dropdown' do
  let(:user) { create(:user) }

  context 'group-specific links' do
    let(:group) { create(:group) }

    before do
      stub_current_user(user)

      assign(:group, group)
    end

    context 'as a Group owner' do
      before do
        group.add_owner(user)
      end

      it 'has a "New project" link' do
        render

        expect(rendered).to have_link(
          'New project',
          href: new_project_path(namespace_id: group.id)
        )
      end

      it 'has a "New subgroup" link' do
        render

        expect(rendered).to have_link(
          'New subgroup',
          href: new_group_path(parent_id: group.id)
        )
      end
    end
  end

  context 'project-specific links' do
    let(:project) { create(:project, creator: user, namespace: user.namespace) }

    before do
      assign(:project, project)
    end

    context 'as a Project owner' do
      before do
        stub_current_user(user)
      end

      it 'has a "New issue" link' do
        render

        expect(rendered).to have_link(
          'New issue',
          href: new_project_issue_path(project)
        )
      end

      it 'has a "New merge request" link' do
        render

        expect(rendered).to have_link(
          'New merge request',
          href: project_new_merge_request_path(project)
        )
      end

      it 'has a "New snippet" link' do
        render

        expect(rendered).to have_link(
          'New snippet',
          href: new_project_snippet_path(project)
        )
      end
    end

    context 'as a Project guest' do
      let(:guest) { create(:user) }

      before do
        stub_current_user(guest)
        project.add_guest(guest)
      end

      it 'has no "New merge request" link' do
        render

        expect(rendered).not_to have_link('New merge request')
      end

      it 'has no "New snippet" link' do
        render

        expect(rendered).not_to have_link(
          'New snippet',
          href: new_project_snippet_path(project)
        )
      end
    end
  end

  context 'global links' do
    before do
      stub_current_user(user)
    end

    it 'has a "New project" link' do
      render

      expect(rendered).to have_link('New project', href: new_project_path)
    end

    it 'has a "New group" link' do
      render

      expect(rendered).to have_link('New group', href: new_group_path)
    end

    it 'has a "New snippet" link' do
      render

      expect(rendered).to have_link('New snippet', href: new_snippet_path)
    end

    context 'when the user is not allowed to create snippets' do
      let(:user) { create(:user, :external)}

      it 'has no "New snippet" link' do
        render

        expect(rendered).not_to have_link('New snippet', href: new_snippet_path)
      end
    end
  end

  def stub_current_user(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
  end
end
