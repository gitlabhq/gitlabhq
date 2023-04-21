# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnalyticsIssueEntity do
  let(:user) { create(:user) }
  let(:entity_hash) do
    {
      total_time: "172802.724419",
      title: "Eos voluptatem inventore in sed.",
      iid: "1",
      id: "1",
      created_at: "2016-11-12 15:04:02.948604",
      end_event_timestamp: "2022-05-24 14:33:01.529701",
      author: user,
      project_path: project.path,
      namespace_path: project.namespace.route.path
    }
  end

  let(:request) { EntityRequest.new(entity: :merge_request) }

  let(:entity) do
    described_class.new(entity_hash, request: request, project: project)
  end

  shared_examples 'generic entity' do
    it 'contains the entity URL' do
      expect(subject).to include(:url)
    end

    it 'contains the author' do
      expect(subject).to include(:author)
    end

    it 'contains the project path' do
      expect(subject).to include(:project_path)
    end

    it 'contains the namespace full path' do
      expect(subject).to include(:namespace_full_path)
    end

    it 'contains the end event timestamp' do
      expect(entity.as_json[:end_event_timestamp]).to match(/ ago$/)
    end

    it 'does not contain sensitive information' do
      expect(subject).not_to include(/token/)
      expect(subject).not_to include(/variables/)
    end

    context 'when end_event_timestamp is nil' do
      let(:entity_hash) do
        {
          total_time: "172802.724419",
          title: "Eos voluptatem inventore in sed.",
          iid: "1",
          id: "1",
          created_at: "2016-11-12 15:04:02.948604",
          end_event_timestamp: nil,
          author: user,
          project_path: project.path,
          namespace_path: project.namespace.route.path
        }
      end

      it 'contains a nil end_event_timestamp' do
        expect(entity.as_json[:end_event_timestamp]).to be_nil
      end
    end
  end

  context 'without subgroup' do
    let_it_be(:project) { create(:project) }

    subject { entity.as_json }

    it_behaves_like 'generic entity'
  end

  context 'with subgroup' do
    let_it_be(:project) { create(:project, :in_subgroup) }

    subject { entity.as_json }

    it_behaves_like 'generic entity'

    it 'has URL containing subgroup' do
      expect(subject[:url]).to include("#{project.group.parent.name}/#{project.group.name}/#{project.path}/")
    end
  end
end
