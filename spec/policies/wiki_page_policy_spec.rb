# frozen_string_literal: true

require 'spec_helper'

describe WikiPagePolicy do
  include_context 'ProjectPolicyTable context'
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :wiki_repo, project_level) }
  let(:user) { create_user_from_membership(project, membership) }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki) }

  subject(:policy) { described_class.new(user, wiki_page) }

  where(:project_level, :feature_access_level, :membership, :expected_count) do
    permission_table_for_guest_feature_access
  end

  with_them do
    it "grants permission" do
      update_feature_access_level(project, feature_access_level)

      if expected_count == 1
        expect(policy).to be_allowed(:read_wiki_page)
      else
        expect(policy).to be_disallowed(:read_wiki_page)
      end
    end
  end
end
