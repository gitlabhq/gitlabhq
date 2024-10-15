# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mailer previews', feature_category: :shared do
  # Setup needed for email previews
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :import_failed, group: group, import_last_error: 'some error') }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:issue) { create(:issue, project: project, milestone: milestone) }
  let_it_be(:remote_mirror) { create(:remote_mirror, project: project) }
  let_it_be(:review) { create(:review, project: project, merge_request: merge_request, author: user) }
  let_it_be(:key) { create(:key, user: user) }
  let_it_be(:bulk_import) { create(:bulk_import, :finished, :with_configuration) }
  let_it_be(:source_user) do
    create(:import_source_user, :awaiting_approval, :with_reassigned_by_user, namespace: group, reassign_to_user: user)
  end

  Gitlab.ee do
    let_it_be(:epic) { create(:epic, group: group) }
  end

  let(:expected_kind) { [Mail::Message, ActionMailer::MessageDelivery] }

  let(:pending_failures) do
    {
      'NotifyPreview#note_merge_request_email_for_diff_discussion' =>
        'https://gitlab.com/gitlab-org/gitlab/-/issues/372885'
    }
  end

  before_all do
    create(:project_member, :maintainer, source: project, created_by: user)
    create(:project_member, :invited, source: project, created_by: user)
    create(:group_member, :access_request, source: group)
    create(:group_member, :access_request, source: create(:group, :private))
  end

  subject { preview.call(email) }

  where(:preview, :email) do
    ActionMailer::Preview.all.flat_map { |preview| preview.emails.map { |email| [preview, email] } }
  end

  with_them do
    it do
      issue_link = pending_failures["#{preview.name}##{email}"]
      pending "See #{issue_link}" if issue_link

      is_expected.to be_kind_of(Mail::Message).or(be_kind_of(ActionMailer::MessageDelivery))
    end
  end
end
