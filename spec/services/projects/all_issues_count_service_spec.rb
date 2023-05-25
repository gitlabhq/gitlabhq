# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AllIssuesCountService, :use_clean_rails_memory_store_caching, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:banned_user) { create(:user, :banned) }

  subject { described_class.new(project) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    it 'returns the number of all issues' do
      create(:issue, :opened, project: project)
      create(:issue, :opened, confidential: true, project: project)
      create(:issue, :opened, author: banned_user, project: project)
      create(:issue, :closed, project: project)

      expect(subject.count).to eq(4)
    end
  end
end
