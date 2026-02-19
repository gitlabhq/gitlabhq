# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::BuildService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let(:user) { guest }

  def build_work_item(work_item_params = {})
    described_class.new(container: project, current_user: user, params: work_item_params).execute
  end

  describe '#execute' do
    subject(:work_item) { described_class.new(container: project, current_user: user, params: {}).execute }

    it { is_expected.to be_a(::WorkItem) }

    it 'returns a work item instance' do
      expect(work_item.class.name).to eq('WorkItem')
    end

    it 'sets the correct container' do
      expect(work_item.project).to eq(project)
    end

    context 'with basic parameters' do
      let(:params) { { title: 'Test Work Item', description: 'A test work item' } }

      subject(:work_item_with_params) { build_work_item(params) }

      it 'builds a work item with title' do
        expect(work_item_with_params.title).to eq('Test Work Item')
      end

      it 'builds a work item with description' do
        expect(work_item_with_params.description).to eq('A test work item')
      end

      it 'sets the author to the current user' do
        expect(work_item_with_params.author).to eq(user)
      end

      it 'is not persisted' do
        expect(work_item_with_params).to be_new_record
      end
    end

    context 'with work item type parameters' do
      let_it_be(:type_task) { WorkItems::Type.default_by_type(:task) }

      it 'builds a work item with the specified type' do
        params = { work_item_type_id: type_task.id }
        work_item = build_work_item(params)

        expect(work_item.work_item_type.base_type).to eq(type_task.base_type)
      end
    end

    context 'with confidential parameter' do
      it 'builds a confidential work item' do
        params = { confidential: true }
        work_item = build_work_item(params)

        expect(work_item.confidential).to be(true)
      end

      it 'builds a non-confidential work item' do
        params = { confidential: false }
        work_item = build_work_item(params)

        expect(work_item.confidential).to be(false)
      end
    end
  end

  describe '#related_issue' do
    let_it_be(:related_work_item) { create(:work_item, project: project) }

    let(:service) do
      described_class.new(
        container: project,
        current_user: user,
        params: { add_related_issue: related_work_item.iid }
      )
    end

    context 'when user has permission to read the related issue' do
      let(:user) { developer }

      it 'returns the related work item' do
        expect(service.related_issue).to eq(related_work_item)
      end
    end

    context 'when user does not have permission to read the related issue' do
      let(:user) { create(:user) }

      it 'returns nil' do
        expect(service.related_issue).to be_nil
      end
    end

    context 'when the related issue does not exist' do
      let(:service) do
        described_class.new(
          container: project,
          current_user: user,
          params: { add_related_issue: 99999 }
        )
      end

      it 'returns nil' do
        expect(service.related_issue).to be_nil
      end
    end

    context 'when add_related_issue param is not provided' do
      let(:service) do
        described_class.new(
          container: project,
          current_user: user,
          params: {}
        )
      end

      it 'returns nil' do
        expect(service.related_issue).to be_nil
      end
    end
  end

  describe '#model_klass' do
    it 'returns WorkItem class' do
      service = described_class.new(container: project, current_user: user, params: {})

      expect(service.send(:model_klass)).to eq(::WorkItem)
    end
  end
end
