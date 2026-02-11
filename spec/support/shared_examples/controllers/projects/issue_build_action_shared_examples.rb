# frozen_string_literal: true

RSpec.shared_examples 'issue building actions' do |assigned_name: :issue|
  context 'when user is not logged in' do
    it 'redirects to sign in page' do
      get :new, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'when user is logged in' do
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    it 'builds a new issue', :aggregate_failures do
      get :new, params: { namespace_id: project.namespace, project_id: project }

      expect(assigns(assigned_name)).to be_a_new(Issue)
      expect(assigns(assigned_name).work_item_type.base_type).to eq('issue')
    end

    where(:conf_value, :conf_result) do
      [
        [true, true],
        ['true', true],
        ['TRUE', true],
        [false, false],
        ['false', false],
        ['FALSE', false]
      ]
    end

    with_them do
      it 'sets the confidential flag to the expected value' do
        get :new, params: {
          namespace_id: project.namespace,
          project_id: project,
          issue: {
            confidential: conf_value
          }
        }

        assigned_issue = assigns(assigned_name)
        expect(assigned_issue).to be_a_new(Issue)
        expect(assigned_issue.confidential).to eq conf_result
      end
    end

    context 'when setting issue type' do
      let(:issue_type) { 'issue' }

      before do
        get :new, params: {
          namespace_id: project.namespace,
          project_id: project,
          issue: { issue_type: issue_type }
        }
      end

      subject { assigns(assigned_name).work_item_type.base_type }

      it { is_expected.to eq('issue') }

      context 'when incident issue' do
        let(:issue_type) { 'incident' }

        it { is_expected.to eq(issue_type) }
      end
    end

    it 'fills in an issue for a merge request' do
      project_with_repository = create(:project, :repository)
      project_with_repository.add_developer(user)
      mr = create(:merge_request_with_diff_notes, source_project: project_with_repository)

      get :new,
        params: {
          namespace_id: project_with_repository.namespace,
          project_id: project_with_repository,
          merge_request_to_resolve_discussions_of: mr.iid
        }

      expect(assigns(assigned_name).title).not_to be_empty
      expect(assigns(assigned_name).description).not_to be_empty
    end

    it 'fills in an issue for a discussion' do
      note = create(:note_on_merge_request, project: project)

      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_resolve_thread_in_issue_action).with(user: user)

      get :new,
        params: {
          namespace_id: project.namespace.path,
          project_id: project,
          merge_request_to_resolve_discussions_of: note.noteable.iid,
          discussion_to_resolve: note.discussion_id
        }

      expect(assigns(assigned_name).title).not_to be_empty
      expect(assigns(assigned_name).description).not_to be_empty
    end
  end
end
