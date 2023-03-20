# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::FindOrCreateService, feature_category: :team_planning do
  describe '#execute' do
    subject(:service) { described_class.new(project, user, params) }

    let(:user)    { create(:user) }
    let(:group)   { create(:group) }
    let(:project) { create(:project, namespace: group) }
    let(:params) do
      {
        title: '1.0',
        description: 'First Release',
        start_date: Date.today,
        due_date: Date.today + 1.month
      }.with_indifferent_access
    end

    context 'when finding milestone on project level' do
      let!(:existing_project_milestone) { create(:milestone, project: project, title: '1.0') }

      it 'returns existing milestone' do
        expect(service.execute).to eq(existing_project_milestone)
      end
    end

    context 'when finding milestone on group level' do
      let!(:existing_group_milestone) { create(:milestone, group: group, title: '1.0') }

      it 'returns existing milestone' do
        expect(service.execute).to eq(existing_group_milestone)
      end
    end

    context 'when not finding milestone' do
      context 'when user has permissions' do
        before do
          project.add_developer(user)
        end

        context 'when params are valid' do
          it 'creates a new milestone at project level using params' do
            expect { service.execute }.to change(project.milestones, :count).by(1)

            milestone = project.reload.milestones.last

            expect(milestone.title).to eq(params[:title])
            expect(milestone.description).to eq(params[:description])
            expect(milestone.start_date).to eq(params[:start_date])
            expect(milestone.due_date).to eq(params[:due_date])
          end
        end

        context 'when params are not valid' do
          before do
            params[:start_date] = Date.today + 2.months
          end

          it 'returns nil' do
            expect(service.execute).to be_nil
          end
        end
      end

      context 'when user does not have permissions' do
        before do
          project.add_guest(user)
        end

        it 'does not create a new milestone' do
          expect { service.execute }.not_to change(project.milestones, :count)
        end

        it 'returns nil' do
          expect(service.execute).to be_nil
        end
      end
    end
  end
end
