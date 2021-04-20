# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SearchContext::Builder, type: :controller do
  controller(ApplicationController) { }

  subject(:builder) { described_class.new(controller.view_context) }

  shared_examples "has a fluid interface" do
    it { is_expected.to be_instance_of(described_class) }
  end

  def expected_project_metadata(project)
    return {} if project.nil?

    a_hash_including(project_path: project.path,
                     name: project.name,
                     issues_path: a_string_including("/issues"),
                     mr_path: a_string_including("/merge_requests"),
                     issues_disabled: !project.issues_enabled?)
  end

  def expected_group_metadata(group)
    return {} if group.nil?

    a_hash_including(group_path: group.path,
                     name: group.name,
                     issues_path: a_string_including("/issues"),
                     mr_path: a_string_including("/merge_requests"))
  end

  def expected_search_url(project, group)
    if project
      search_path(project_id: project.id)
    elsif group
      search_path(group_id: group.id)
    else
      search_path
    end
  end

  def be_search_context(project: nil, group: nil, snippets: [], ref: nil)
    group = project ? project.group : group
    snippets.compact!
    ref = ref

    have_attributes(
      project: project,
      group: group,
      ref: ref,
      snippets: snippets,
      project_metadata: expected_project_metadata(project),
      group_metadata: expected_group_metadata(group),
      search_url: expected_search_url(project, group)
    )
  end

  describe '#with_project' do
    let(:project) { create(:project) }

    subject { builder.with_project(project) }

    it_behaves_like "has a fluid interface"

    describe '#build!' do
      subject(:context) { builder.with_project(project).build! }

      context 'when a project is not owned by a group' do
        it { is_expected.to be_for_project }
        it { is_expected.to be_search_context(project: project) }
      end

      context 'when a project is owned by a group' do
        let(:project) { create(:project, group: create(:group)) }

        it 'delegates to `#with_group`' do
          expect(builder).to receive(:with_group).with(project.group)
          expect(context).to be
        end

        it { is_expected.to be_search_context(project: project, group: project.group) }
      end
    end
  end

  describe '#with_snippet' do
    context 'when there is a single snippet' do
      let(:snippet) { create(:snippet) }

      subject { builder.with_snippet(snippet) }

      it_behaves_like "has a fluid interface"

      describe '#build!' do
        subject(:context) { builder.with_snippet(snippet).build! }

        it { is_expected.to be_for_snippet }
        it { is_expected.to be_search_context(snippets: [snippet]) }
      end
    end

    context 'when there are multiple snippets' do
      let(:snippets) { create_list(:snippet, 3) }

      describe '#build!' do
        subject(:context) do
          snippets.each(&builder.method(:with_snippet))
          builder.build!
        end

        it { is_expected.to be_for_snippet }
        it { is_expected.to be_search_context(snippets: snippets) }
      end
    end
  end

  describe '#with_group' do
    let(:group) { create(:group) }

    subject { builder.with_group(group) }

    it_behaves_like "has a fluid interface"

    describe '#build!' do
      subject(:context) { builder.with_group(group).build! }

      it { is_expected.to be_for_group }
      it { is_expected.to be_search_context(group: group) }

      context 'with group scope' do
        let(:action_name) { '' }

        before do
          allow(controller).to receive(:controller_name).and_return('groups')
          allow(controller).to receive(:action_name).and_return(action_name)
        end

        it 'returns nil without groups controller action' do
          expect(subject.scope).to be(nil)
        end

        context 'when on issues scope' do
          let(:action_name) { 'issues' }

          it 'search context returns issues scope' do
            expect(subject.scope).to be('issues')
          end
        end

        context 'when on merge requests scope' do
          let(:action_name) { 'merge_requests' }

          it 'search context returns issues scope' do
            expect(subject.scope).to be('merge_requests')
          end
        end
      end
    end
  end

  describe '#with_ref' do
    let(:ref) { Gitlab::Git::EMPTY_TREE_ID }

    subject { builder.with_ref(ref) }

    it_behaves_like "has a fluid interface"

    describe '#build!' do
      subject(:context) { builder.with_ref(ref).build! }

      it { is_expected.to be_search_context(ref: ref) }
    end
  end

  describe '#build!' do
    subject(:context) { builder.build! }

    it { is_expected.to be_a(Gitlab::SearchContext) }
  end
end
