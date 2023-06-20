# frozen_string_literal: true

RSpec.shared_examples 'search results filtered by labels' do
  let(:project_label) { create(:label, project: project) }
  let!(:issue_1) { create(:labeled_issue, labels: [project_label], project: project, title: 'foo project') }
  let!(:unlabeled_issue) { create(:issue, project: project, title: 'foo unlabeled') }

  let(:filters) { { labels: [project_label.id] } }

  before do
    ensure_elasticsearch_index!
  end

  subject(:issue_results) { results.objects(scope) }

  it 'filters by labels', :sidekiq_inline do
    expect(issue_results).to contain_exactly(issue_1)
  end
end
