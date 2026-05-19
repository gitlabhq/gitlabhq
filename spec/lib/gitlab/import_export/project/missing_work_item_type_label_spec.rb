# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::MissingWorkItemTypeLabel, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:type_name) { 'Custom Bug' }
  let(:expected_title) { "#{_('imported')}:Custom Bug" }
  let(:expected_description) do
    _('Work items with this label were imported with a work item type name that ' \
      'could not be resolved in this namespace. They were assigned the default ' \
      'issue type instead.')
  end

  subject(:finder) { described_class.new(project) }

  describe '#id_for' do
    it 'finds-or-creates a label with the expected title, color and description' do
      expect { finder.id_for(type_name) }.to change { project.labels.count }.by(1)

      label = project.labels.find_by(title: expected_title)
      expect(label).to be_present
      expect(label.color.to_s).to eq(::Gitlab::Color.color_for(expected_title).to_s)
      expect(label.description).to eq(expected_description)
    end

    it 'returns the created label id' do
      label_id = finder.id_for(type_name)

      expect(label_id).to eq(project.labels.find_by(title: expected_title).id)
    end

    it 'reuses the same label on subsequent calls' do
      first_id = finder.id_for(type_name)

      expect { finder.id_for(type_name) }.not_to change { project.labels.count }
      expect(finder.id_for(type_name)).to eq(first_id)
    end

    it 'reuses an existing label with the same title' do
      existing = create(:label, project: project, title: expected_title)

      expect { finder.id_for(type_name) }.not_to change { project.labels.count }
      expect(finder.id_for(type_name)).to eq(existing.id)
    end

    it 'caches the label id in Redis' do
      label_id = finder.id_for(type_name)
      cache_key = format(described_class::CACHE_KEY, project_id: project.id, name: type_name)

      expect(::Gitlab::Cache::Import::Caching.read_integer(cache_key)).to eq(label_id)
    end

    it 'returns the cached id on subsequent calls without hitting the DB' do
      finder.id_for(type_name)

      expect(::Labels::FindOrCreateService).not_to receive(:new)

      finder.id_for(type_name)
    end

    context 'when label creation fails' do
      before do
        allow_next_instance_of(::Labels::FindOrCreateService) do |service|
          allow(service).to receive(:execute).and_return(nil)
        end
      end

      it 'returns nil and does not cache anything' do
        expect(finder.id_for(type_name)).to be_nil

        cache_key = format(described_class::CACHE_KEY, project_id: project.id, name: type_name)
        expect(::Gitlab::Cache::Import::Caching.read_integer(cache_key)).to be_nil
      end
    end
  end
end
