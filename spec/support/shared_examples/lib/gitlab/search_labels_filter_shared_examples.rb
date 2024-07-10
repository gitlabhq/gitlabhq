# frozen_string_literal: true

RSpec.shared_examples 'search results filtered by labels' do
  let_it_be(:project_label) { create(:label, project: project) }
  let_it_be(:labeled_issue) { create(:labeled_issue, labels: [project_label], project: project, title: 'foo project') }
  let_it_be(:unlabeled_issue) { create(:issue, project: project, title: 'foo unlabeled') }

  before do
    ::Elastic::ProcessBookkeepingService.track!(labeled_issue)
    ::Elastic::ProcessBookkeepingService.track!(unlabeled_issue)
    ensure_elasticsearch_index!
  end

  context 'when labels filter is provided' do
    let(:filters) { { labels: [project_label.id] } }

    it 'filters by labels', :sidekiq_inline do
      expect(results.objects(scope)).to contain_exactly(labeled_issue)
    end
  end

  context 'when label_name filter is provided' do
    let(:filters) { { label_name: [project_label.name] } }

    it 'filters by labels', :sidekiq_inline do
      expect(results.objects(scope)).to contain_exactly(labeled_issue)
    end
  end

  context 'when both labels and label_name filters are provided' do
    let(:filters) { { labels: [0], label_name: [project_label.name] } }

    it 'uses label_name filter and filters by labels', :sidekiq_inline do
      expect(results.objects(scope)).to contain_exactly(labeled_issue)
    end
  end
end
