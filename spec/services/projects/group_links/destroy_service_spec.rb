# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::DestroyService, '#execute' do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:group) { create(:group) }
  let!(:group_link) { create(:project_group_link, project: project, group: group) }

  subject { described_class.new(project, user) }

  it 'removes group from project' do
    expect { subject.execute(group_link) }.to change { project.project_group_links.count }.from(1).to(0)
  end

  it 'updates authorization' do
    group.add_maintainer(user)

    expect { subject.execute(group_link) }.to(
      change { Ability.allowed?(user, :read_project, project) }
        .from(true).to(false))
  end

  it 'returns false if group_link is blank' do
    expect { subject.execute(nil) }.not_to change { project.project_group_links.count }
  end

  describe 'todos cleanup' do
    context 'when project is private' do
      it 'triggers todos cleanup' do
        expect(TodosDestroyer::ProjectPrivateWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)
        expect(project.private?).to be true

        subject.execute(group_link)
      end
    end

    context 'when project is public or internal' do
      shared_examples_for 'removes confidential todos' do
        it 'does not trigger todos cleanup' do
          expect(TodosDestroyer::ProjectPrivateWorker).not_to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)
          expect(TodosDestroyer::ConfidentialIssueWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, nil, project.id)
          expect(project.private?).to be false

          subject.execute(group_link)
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'removes confidential todos'
      end

      context 'when project is internal' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'removes confidential todos'
      end
    end
  end
end
