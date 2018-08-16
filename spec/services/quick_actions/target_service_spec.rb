# frozen_string_literal: true

require 'spec_helper'

describe QuickActions::TargetService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    shared_examples 'no target' do |type_id:|
      it 'returns nil' do
        target = service.execute(type, type_id)

        expect(target).to be_nil
      end
    end

    shared_examples 'find target' do
      it 'returns the target' do
        found_target = service.execute(type, target_id)

        expect(found_target).to eq(target)
      end
    end

    shared_examples 'build target' do |type_id:|
      it 'builds a new target' do
        target = service.execute(type, type_id)

        expect(target.project).to eq(project)
        expect(target).to be_new_record
      end
    end

    context 'for issue' do
      let(:target) { create(:issue, project: project) }
      let(:target_id) { target.iid }
      let(:type) { 'Issue' }

      it_behaves_like 'find target'
      it_behaves_like 'build target', type_id: nil
      it_behaves_like 'build target', type_id: -1
    end

    context 'for merge request' do
      let(:target) { create(:merge_request, source_project: project) }
      let(:target_id) { target.iid }
      let(:type) { 'MergeRequest' }

      it_behaves_like 'find target'
      it_behaves_like 'build target', type_id: nil
      it_behaves_like 'build target', type_id: -1
    end

    context 'for commit' do
      let(:project) { create(:project, :repository) }
      let(:target) { project.commit.parent }
      let(:target_id) { target.sha }
      let(:type) { 'Commit' }

      it_behaves_like 'find target'
      it_behaves_like 'no target', type_id: 'invalid_sha'

      context 'with nil target_id' do
        let(:target) { project.commit }
        let(:target_id) { nil }

        it_behaves_like 'find target'
      end
    end

    context 'for unknown type' do
      let(:type) { 'unknown' }

      it_behaves_like 'no target', type_id: :unused
    end
  end
end
