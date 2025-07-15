# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Milestone, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }

  shared_examples 'builds milestone hook data' do
    it { expect(data).to be_a(Hash) }

    it 'includes the correct structure' do
      expect(data[:object_kind]).to eq('milestone')
      expect(data[:event_type]).to eq('milestone')
      expect(data[:action]).to eq(action)
    end
  end

  describe '.build' do
    let(:milestone) { create(:milestone, project: project) }
    let(:action) { 'create' }

    subject(:data) { described_class.build(milestone, action) }

    it_behaves_like 'builds milestone hook data'

    it 'includes project data' do
      expect(data[:project]).to eq(milestone.project.hook_attrs)
    end

    it 'includes milestone attributes' do
      object_attributes = data[:object_attributes]

      expect(object_attributes[:id]).to eq(milestone.id)
      expect(object_attributes[:iid]).to eq(milestone.iid)
      expect(object_attributes[:title]).to eq(milestone.title)
      expect(object_attributes[:description]).to eq(milestone.description)
      expect(object_attributes[:state]).to eq(milestone.state)
      expect(object_attributes[:created_at]).to eq(milestone.created_at)
      expect(object_attributes[:updated_at]).to eq(milestone.updated_at)
      expect(object_attributes[:due_date]).to eq(milestone.due_date)
      expect(object_attributes[:start_date]).to eq(milestone.start_date)
      expect(object_attributes[:project_id]).to eq(milestone.project_id)
    end

    context 'with different actions' do
      %w[create close reopen].each do |test_action|
        context "when action is #{test_action}" do
          let(:action) { test_action }

          it "sets the action to #{test_action}" do
            expect(data[:action]).to eq(test_action)
          end
        end
      end
    end

    context 'with milestone having dates' do
      let(:milestone) { create(:milestone, project: project, due_date: 1.week.from_now, start_date: 1.day.ago) }

      it 'includes the date information' do
        expect(data[:object_attributes][:due_date]).to eq(milestone.due_date)
        expect(data[:object_attributes][:start_date]).to eq(milestone.start_date)
      end
    end

    context 'with milestone having no dates' do
      let(:milestone) { create(:milestone, project: project, due_date: nil, start_date: nil) }

      it 'includes nil date information' do
        expect(data[:object_attributes][:due_date]).to be_nil
        expect(data[:object_attributes][:start_date]).to be_nil
      end
    end

    context 'with closed milestone' do
      let(:milestone) { create(:milestone, :closed, project: project) }

      it 'includes the correct state' do
        expect(data[:object_attributes][:state]).to eq('closed')
      end
    end

    include_examples 'project hook data'
  end

  describe '.build_sample' do
    let(:action) { 'create' }

    context 'when project has existing milestones' do
      subject(:data) { described_class.build_sample(project) }

      let_it_be(:existing_milestone) { create(:milestone, project: project) }

      it_behaves_like 'builds milestone hook data'

      it 'includes project data' do
        expect(data[:project]).to eq(project.hook_attrs)
      end

      it 'uses the first existing milestone' do
        expect(data[:object_attributes][:id]).to eq(existing_milestone.id)
        expect(data[:object_attributes][:title]).to eq(existing_milestone.title)
      end

      include_examples 'project hook data'
    end

    context 'when project has no milestones' do
      subject(:data) { described_class.build_sample(clean_project) }

      let_it_be(:clean_project) { create(:project) }

      it_behaves_like 'builds milestone hook data'

      it 'includes project data' do
        expect(data[:project]).to eq(clean_project.hook_attrs)
      end

      it 'creates a sample milestone with predefined data' do
        expect(data[:object_attributes][:title]).to eq('Sample milestone')
        expect(data[:object_attributes][:description]).to eq('Sample milestone description')
        expect(data[:object_attributes][:state]).to eq('active')
      end

      include_examples 'project hook data' do
        let(:project) { clean_project }
      end
    end
  end
end
