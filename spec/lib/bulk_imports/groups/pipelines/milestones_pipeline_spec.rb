# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::MilestonesPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:timestamp) { Time.new(2020, 01, 01).utc }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path,
      group: group
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  before do
    group.add_owner(user)
  end

  describe '#run' do
    it 'imports group milestones' do
      first_page = extracted_data(title: 'milestone1', iid: 1, has_next_page: true)
      last_page = extracted_data(title: 'milestone2', iid: 2)

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run }.to change(Milestone, :count).by(2)

      expect(group.milestones.pluck(:title)).to contain_exactly('milestone1', 'milestone2')

      milestone = group.milestones.last

      expect(milestone.description).to eq('desc')
      expect(milestone.state).to eq('closed')
      expect(milestone.start_date.to_s).to eq('2020-10-21')
      expect(milestone.due_date.to_s).to eq('2020-10-22')
      expect(milestone.created_at).to eq(timestamp)
      expect(milestone.updated_at).to eq(timestamp)
    end
  end

  describe '#load' do
    it 'creates the milestone' do
      data = milestone_data('milestone')

      expect { subject.load(context, data) }.to change(Milestone, :count).by(1)
    end

    context 'when user is not authorized to create the milestone' do
      before do
        allow(user).to receive(:can?).with(:admin_milestone, group).and_return(false)
      end

      it 'raises NotAllowedError' do
        data = extracted_data(title: 'milestone')

        expect { subject.load(context, data) }.to raise_error(::BulkImports::Pipeline::NotAllowedError)
      end
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: {
            query: BulkImports::Groups::Graphql::GetMilestonesQuery
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
        )
    end
  end

  def milestone_data(title, iid: 1)
    {
      'title' => title,
      'description' => 'desc',
      'iid' => iid,
      'state' => 'closed',
      'start_date' => '2020-10-21',
      'due_date' => '2020-10-22',
      'created_at' => timestamp.to_s,
      'updated_at' => timestamp.to_s
    }
  end

  def extracted_data(title:, iid: 1, has_next_page: false)
    page_info = {
      'has_next_page' => has_next_page,
      'next_page' => has_next_page ? 'cursor' : nil
    }

    BulkImports::Pipeline::ExtractedData.new(
      data: milestone_data(title, iid: iid),
      page_info: page_info
    )
  end
end
