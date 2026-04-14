# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::QuickActions::DependencyService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:other_issue) { create(:issue, project: project) }

  subject(:service) { described_class.new(target, user, project) }

  before_all do
    project.add_reporter(user)
  end

  describe '#can_admin_link?' do
    context 'when target is an Issue' do
      let(:target) { issue }

      it 'returns true when user has permission' do
        expect(service.can_admin_link?).to be(true)
      end

      context 'when user lacks permission' do
        let_it_be(:guest_user) { create(:user) }

        subject(:service) { described_class.new(issue, guest_user, project) }

        it 'returns false' do
          expect(service.can_admin_link?).to be(false)
        end
      end
    end

    context 'when target is not an Issue' do
      let(:target) { create(:merge_request, source_project: project) }

      it 'returns false' do
        expect(service.can_admin_link?).to be(false)
      end
    end
  end

  describe '#param_hint' do
    let(:target) { issue }

    it 'returns the work item reference hint' do
      expect(service.param_hint).to eq('<#item | group/project#item | item URL>')
    end
  end

  describe '#type_name' do
    let(:target) { issue }

    it 'returns the work item type name' do
      expect(service.type_name).to eq('issue')
    end
  end

  describe '#parse_params' do
    let(:target) { issue }

    it 'extracts issue references from text' do
      refs = service.parse_params(other_issue.to_reference)
      expect(refs).to contain_exactly(other_issue)
    end
  end

  describe '#format_ref' do
    let(:target) { issue }

    it 'returns the reference relative to the target project' do
      expect(service.format_ref(other_issue)).to eq(other_issue.to_reference(project))
    end
  end

  describe '#format_refs' do
    let(:target) { issue }
    let_it_be(:third_issue) { create(:issue, project: project) }

    it 'returns a sentence of references' do
      result = service.format_refs([other_issue, third_issue])
      expect(result).to eq("#{other_issue.to_reference(project)} and #{third_issue.to_reference(project)}")
    end
  end

  describe '#create_link' do
    let(:target) { issue }

    it 'creates a related work item link' do
      expect { service.create_link([other_issue], link_type: 'relates_to') }
        .to change { IssueLink.count }.by(1)
    end
  end

  describe '#destroy_link' do
    let(:target) { issue }

    before do
      create(:issue_link, source: issue, target: other_issue)
    end

    it 'destroys the link between items' do
      expect { service.destroy_link(other_issue) }
        .to change { IssueLink.count }.by(-1)
    end

    context 'when no link exists' do
      let_it_be(:unlinked_issue) { create(:issue, project: project) }

      it 'does nothing' do
        expect { service.destroy_link(unlinked_issue) }
          .not_to change { IssueLink.count }
      end
    end
  end
end
