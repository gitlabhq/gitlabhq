# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_new_dropdown' do
  let_it_be(:user) { create(:user) }

  shared_examples_for 'invite member quick link' do
    context 'when an experiment is active' do
      before do
        allow(Gitlab::Experimentation).to receive(:active?).and_return(true)
        allow(view).to receive(:experiment_tracking_category_and_group)
        allow(view).to receive(:tracking_label)
      end

      context 'with ability to invite members' do
        it { is_expected.to have_link('Invite members', href: href) }

        it 'records the experiment' do
          subject

          expect(view).to have_received(:experiment_tracking_category_and_group)
                            .with(:invite_members_new_dropdown)
          expect(view).to have_received(:tracking_label)
        end
      end

      context 'without ability to invite members' do
        let(:invite_member) { false }

        it { is_expected.not_to have_link('Invite members') }
      end
    end

    context 'when experiment is not active' do
      it { is_expected.not_to have_link('Invite members') }
    end
  end

  context 'group-specific links' do
    let_it_be(:group) { create(:group) }

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

        expect(rendered).to have_link('New project', href: new_project_path(namespace_id: group.id))
      end

      it 'has a "New subgroup" link' do
        render

        expect(rendered).to have_link('New subgroup', href: new_group_path(parent_id: group.id))
      end
    end

    describe 'invite members quick link' do
      let(:href) { group_group_members_path(group) }
      let(:invite_member) { true }

      before do
        allow(view).to receive(:can?).with(user, :create_projects, group).and_return(true)
        allow(view).to receive(:can?).with(user, :admin_group_member, group).and_return(invite_member)
        allow(view).to receive(:can_import_members?).and_return(invite_member)
        allow(view).to receive(:experiment_enabled?)
      end

      subject do
        render

        rendered
      end

      it_behaves_like 'invite member quick link'
    end
  end

  context 'project-specific links' do
    let_it_be(:project) { create(:project, creator: user, namespace: user.namespace) }

    before do
      assign(:project, project)
    end

    context 'as a Project owner' do
      before do
        stub_current_user(user)
      end

      it 'has a "New issue" link' do
        render

        expect(rendered).to have_link('New issue', href: new_project_issue_path(project))
      end

      it 'has a "New merge request" link' do
        render

        expect(rendered).to have_link('New merge request', href: project_new_merge_request_path(project))
      end

      it 'has a "New snippet" link' do
        render

        expect(rendered).to have_link('New snippet', href: new_project_snippet_path(project))
      end
    end

    context 'as a Project guest' do
      let_it_be(:guest) { create(:user) }

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

        expect(rendered).not_to have_link('New snippet', href: new_project_snippet_path(project))
      end
    end

    describe 'invite members quick link' do
      let(:invite_member) { true }
      let(:href) { project_project_members_path(project) }

      before do
        allow(view).to receive(:can_import_members?).and_return(invite_member)
        stub_current_user(user)
        allow(view).to receive(:experiment_enabled?)
      end

      subject do
        render

        rendered
      end

      it_behaves_like 'invite member quick link'
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

    context 'when the user is not allowed to do anything' do
      let(:user) { create(:user, :external) }

      it 'is nil' do
        # We have to us `view.render` because `render` causes issues
        # https://github.com/rails/rails/issues/41320
        expect(view.render("layouts/header/new_dropdown")).to be_nil
      end
    end
  end

  def stub_current_user(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
  end
end
