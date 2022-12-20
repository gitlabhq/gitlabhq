# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventFilter do
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:push_event)     { create(:push_event,        project: public_project) }
  let_it_be(:merged_event)   { create(:event, :merged,    project: public_project, target: public_project) }
  let_it_be(:created_event)  { create(:event, :created,   project: public_project, target: create(:issue, project: public_project)) }
  let_it_be(:updated_event)  { create(:event, :updated,   project: public_project, target: create(:issue, project: public_project)) }
  let_it_be(:closed_event)   { create(:event, :closed,    project: public_project, target: create(:issue, project: public_project)) }
  let_it_be(:reopened_event) { create(:event, :reopened,  project: public_project, target: create(:issue, project: public_project)) }
  let_it_be(:comments_event) { create(:event, :commented, project: public_project, target: public_project) }
  let_it_be(:joined_event)   { create(:event, :joined,    project: public_project, target: public_project) }
  let_it_be(:left_event)     { create(:event, :left,      project: public_project, target: public_project) }
  let_it_be(:wiki_page_event) { create(:wiki_page_event) }
  let_it_be(:wiki_page_update_event) { create(:wiki_page_event, :updated) }
  let_it_be(:design_event) { create(:design_event) }

  let_it_be(:work_item_event) do
    create(:event,
      :created,
      project: public_project,
      target: create(:work_item, :task, project: public_project),
      target_type: 'WorkItem'
    )
  end

  describe '#filter' do
    it 'returns "all" if given filter is nil' do
      expect(described_class.new(nil).filter).to eq(described_class::ALL)
    end

    it 'returns "all" if given filter is ""' do
      expect(described_class.new('').filter).to eq(described_class::ALL)
    end

    it 'returns "all" if given filter is "foo"' do
      expect(described_class.new('foo').filter).to eq('all')
    end
  end

  describe '#apply_filter' do
    let(:filtered_events) { described_class.new(filter).apply_filter(Event.all) }

    context 'with the "push" filter' do
      let(:filter) { described_class::PUSH }

      it 'filters push events only' do
        expect(filtered_events).to contain_exactly(push_event)
      end
    end

    context 'with the "merged" filter' do
      let(:filter) { described_class::MERGED }

      it 'filters merged events only' do
        expect(filtered_events).to contain_exactly(merged_event)
      end
    end

    context 'with the "issue" filter' do
      let(:filter) { described_class::ISSUE }

      it 'filters issue and work item events only' do
        expect(filtered_events).to contain_exactly(
          created_event,
          updated_event,
          closed_event,
          reopened_event,
          work_item_event
        )
      end
    end

    context 'with the "comments" filter' do
      let(:filter) { described_class::COMMENTS }

      it 'filters comment events only' do
        expect(filtered_events).to contain_exactly(comments_event)
      end
    end

    context 'with the "team" filter' do
      let(:filter) { described_class::TEAM }

      it 'filters team events only' do
        expect(filtered_events).to contain_exactly(joined_event, left_event)
      end
    end

    context 'with the "all" filter' do
      let(:filter) { described_class::ALL }

      it 'returns all events' do
        expect(filtered_events).to eq(Event.all)
      end
    end

    context 'with the "design" filter' do
      let(:filter) { described_class::DESIGNS }

      it 'returns only design events' do
        expect(filtered_events).to contain_exactly(design_event)
      end
    end

    context 'with the "wiki" filter' do
      let(:filter) { described_class::WIKI }

      it 'returns only wiki page events' do
        expect(filtered_events).to contain_exactly(wiki_page_event, wiki_page_update_event)
      end
    end

    context 'with an unknown filter' do
      let(:filter) { 'foo' }

      it 'returns all events' do
        expect(filtered_events).to eq(Event.all)
      end
    end

    context 'with a nil filter' do
      let(:filter) { nil }

      it 'returns all events' do
        expect(filtered_events).to eq(Event.all)
      end
    end
  end

  describe '#in_operator_query_builder_params' do
    let(:filtered_events) { described_class.new(filter).in_operator_query_builder_params(array_data) }
    let(:array_data) do
      {
        scope_ids: [public_project.id],
        scope_model: Project,
        mapping_column: 'project_id'
      }
    end

    context 'with the "issue" filter' do
      let(:filter) { described_class::ISSUE }

      it 'also includes work item events' do
        expect(filtered_events[:scope]).to contain_exactly(
          created_event,
          updated_event,
          closed_event,
          reopened_event,
          work_item_event
        )
      end
    end
  end

  describe '#active?' do
    let(:event_filter) { described_class.new(described_class::TEAM) }

    it 'returns false if filter does not include the given key' do
      expect(event_filter.active?('foo')).to eq(false)
    end

    it 'returns false if the given key is nil' do
      expect(event_filter.active?(nil)).to eq(false)
    end

    it 'returns true if filter does not include the given key' do
      expect(event_filter.active?(described_class::TEAM)).to eq(true)
    end
  end
end
