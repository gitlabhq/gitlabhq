# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gfm::ReferenceRewriter, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:new_project) { create(:project, name: 'new-project', group: group) }
  let(:old_project) { create(:project, name: 'old-project', group: group) }
  let(:old_project_ref) { old_project.to_reference_base(new_project) }
  let(:text) { 'some text' }
  let(:note) { create(:note, note: text, project: old_project) }

  before do
    old_project.add_reporter(user)
  end

  describe '#rewrite' do
    subject do
      described_class.new(note.note, note.note_html, old_project, user).rewrite(new_project)
    end

    context 'multiple issues and merge requests referenced' do
      let!(:issue_first) { create(:issue, project: old_project) }
      let!(:issue_second) { create(:issue, project: old_project) }
      let!(:merge_request) { create(:merge_request, source_project: old_project) }

      context 'description with ignored elements' do
        let(:text) do
          "Hi. This references #1, but not `#2`\n" \
            '<pre>and not !1</pre>'
        end

        it { is_expected.to include issue_first.to_reference(new_project) }
        it { is_expected.not_to include issue_second.to_reference(new_project) }
        it { is_expected.not_to include merge_request.to_reference(new_project) }
      end

      context 'rewrite ambigous references' do
        context 'url' do
          let(:url) { 'http://gitlab.com/#1' }
          let(:text) { "This references #1, but not #{url}" }

          it { is_expected.to include url }
        end

        context 'code' do
          let(:text) { "#1, but not `[#1]`" }

          it { is_expected.to eq "#{issue_first.to_reference(new_project)}, but not `[#1]`" }
        end

        context 'code reverse' do
          let(:text) { "not `#1`, but #1" }

          it { is_expected.to eq "not `#1`, but #{issue_first.to_reference(new_project)}" }
        end

        context 'code in random order' do
          let(:text) { "#1, `#1`, #1, `#1`" }
          let(:ref) { issue_first.to_reference(new_project) }

          it { is_expected.to eq "#{ref}, `#1`, #{ref}, `#1`" }
        end
      end
    end

    context 'with a commit' do
      let(:old_project) { create(:project, :repository, name: 'old-project', group: group) }
      let(:commit) { old_project.commit }

      context 'reference to an absolute URL to a commit' do
        let(:text) { Gitlab::UrlBuilder.build(commit) }

        it { is_expected.to eq(text) }
      end

      context 'reference to a commit' do
        let(:text) { commit.id }

        it { is_expected.to eq("#{old_project_ref}@#{text}") }
      end
    end

    context 'when referring to a group' do
      let(:text) { "group @#{group.full_path}" }

      it { is_expected.to eq text }
    end

    context 'when referring to a user' do
      let(:text) { "user @#{user.full_path}" }

      it { is_expected.to eq text }
    end

    context 'when referable has a nil reference' do
      before do
        create(:milestone, title: '9.0', project: old_project)

        allow_any_instance_of(Milestone).to receive(:to_reference).and_return(nil)
      end

      let(:text) { 'milestone: %"9.0"' }

      it 'raises an error that should be fixed' do
        expect { subject }.to raise_error(
          described_class::RewriteError,
          'Unspecified reference detected for Milestone'
        )
      end
    end
  end

  describe '#rewrite with table syntax' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:parent_group1) { create(:group, path: "parent-group-one") }
    let_it_be(:parent_group2) { create(:group, path: "parent-group-two") }
    let_it_be(:user) { create(:user) }

    let_it_be(:source_project) { create(:project, path: 'old-project', group: parent_group1) }
    let_it_be(:target_project1) { create(:project, path: 'new-project', group: parent_group1) }
    let_it_be(:target_project2) { create(:project, path: 'new-project', group: parent_group2) }
    let_it_be(:target_group1) { create(:group, path: 'new-group', parent: parent_group1) }
    let_it_be(:target_group2) { create(:group, path: 'new-group', parent: parent_group2) }

    let_it_be(:work_item_project_first) { create(:issue, project: source_project) }

    let_it_be(:merge_request) { create(:merge_request, source_project: source_project) }

    let_it_be(:project_label) { create(:label, id: 123, name: 'pr label1', project: source_project) }
    let_it_be(:parent_group_label) { create(:group_label, id: 321, name: 'gr label1', group: parent_group1) }

    let_it_be(:project_milestone) { create(:milestone, title: 'project milestone', project: source_project) }
    let_it_be(:parent_group_milestone) { create(:milestone, title: 'group milestone', group: parent_group1) }

    before_all do
      parent_group1.add_reporter(user)
      parent_group2.add_reporter(user)
    end

    context 'with source as Project and target as Project within same parent group' do
      let_it_be(:source_parent) { source_project }  # 'parent-group-one/old-project'
      let_it_be(:target_parent) { target_project1 } # 'parent-group-one/new-project'

      where(:source_text, :destination_text) do
        # project level work item reference
        'ref #1'                             | 'ref old-project#1'
        'ref #1+'                            | 'ref old-project#1+'
        'ref #1+s'                           | 'ref old-project#1+s'
        # merge request reference
        'ref !1'                             | 'ref old-project!1'
        'ref !1+'                            | 'ref old-project!1+'
        'ref !1+s'                           | 'ref old-project!1+s'
        # project label reference
        'ref ~123'                           | 'ref old-project~123'
        'ref ~"pr label1"'                   | 'ref old-project~123'
        # group level label reference
        'ref ~321'                           | 'ref old-project~321'
        'ref ~"gr label1"'                   | 'ref old-project~321'
        # project level milestone reference
        'ref %"project milestone"'           | 'ref /parent-group-one/old-project%"project milestone"'
        # group level milestone reference
        'ref %"group milestone"'             | 'ref /parent-group-one%"group milestone"'
      end

      with_them do
        it_behaves_like 'rewrites references correctly'
      end
    end

    context 'with source as Project and target as Project within different parent groups' do
      let_it_be(:source_parent) { source_project }  # 'parent-group-one/old-project'
      let_it_be(:target_parent) { target_project2 } # 'parent-group-two/new-project'

      where(:source_text, :destination_text) do
        # project level work item reference
        'ref #1'                             | 'ref parent-group-one/old-project#1'
        'ref #1+'                            | 'ref parent-group-one/old-project#1+'
        'ref #1+s'                           | 'ref parent-group-one/old-project#1+s'
        # merge request reference
        'ref !1'                             | 'ref parent-group-one/old-project!1'
        'ref !1+'                            | 'ref parent-group-one/old-project!1+'
        'ref !1+s'                           | 'ref parent-group-one/old-project!1+s'
        # project label reference
        'ref ~123'                           | 'ref parent-group-one/old-project~123'
        'ref ~"pr label1"'                   | 'ref parent-group-one/old-project~123'
        # group level label reference
        'ref ~321'                           | 'ref parent-group-one/old-project~321'
        'ref ~"gr label1"'                   | 'ref parent-group-one/old-project~321'
        # project level milestone reference
        'ref %"project milestone"'           | 'ref /parent-group-one/old-project%"project milestone"'
        # group level milestone reference
        'ref %"group milestone"'             | 'ref /parent-group-one%"group milestone"'
      end

      with_them do
        it_behaves_like 'rewrites references correctly'
      end
    end

    context 'with source as Project and target as Group within same parent group' do
      let_it_be(:source_parent) { source_project } # 'parent-group-one/old-project'
      let_it_be(:target_parent) { target_group1 }  # 'parent-group-one/new-group'

      where(:source_text, :destination_text) do
        # project level work item reference
        'ref #1'                             | 'ref parent-group-one/old-project#1'
        'ref #1+'                            | 'ref parent-group-one/old-project#1+'
        'ref #1+s'                           | 'ref parent-group-one/old-project#1+s'
        # merge request reference
        'ref !1'                             | 'ref parent-group-one/old-project!1'
        'ref !1+'                            | 'ref parent-group-one/old-project!1+'
        'ref !1+s'                           | 'ref parent-group-one/old-project!1+s'
        # project label reference
        'ref ~123'                           | 'ref parent-group-one/old-project~123'
        'ref ~"pr label1"'                   | 'ref parent-group-one/old-project~123'
        # group level label reference
        'ref ~321'                           | 'ref parent-group-one/old-project~321'
        'ref ~"gr label1"'                   | 'ref parent-group-one/old-project~321'
        # project level milestone reference
        'ref %"project milestone"'           | 'ref /parent-group-one/old-project%"project milestone"'
        # group level milestone reference
        'ref %"group milestone"'             | 'ref /parent-group-one%"group milestone"'
      end

      with_them do
        it_behaves_like 'rewrites references correctly'
      end
    end

    context 'with source as Project and target as Group within different parent groups' do
      let_it_be(:source_parent) { source_project } # 'parent-group-one/old-project'
      let_it_be(:target_parent) { target_group2 }  # 'parent-group-two/new-group'

      where(:source_text, :destination_text) do
        # project level work item reference
        'ref #1'                             | 'ref parent-group-one/old-project#1'
        'ref #1+'                            | 'ref parent-group-one/old-project#1+'
        'ref #1+s'                           | 'ref parent-group-one/old-project#1+s'
        # merge request reference
        'ref !1'                             | 'ref parent-group-one/old-project!1'
        'ref !1+'                            | 'ref parent-group-one/old-project!1+'
        'ref !1+s'                           | 'ref parent-group-one/old-project!1+s'
        # project label reference
        'ref ~123'                           | 'ref parent-group-one/old-project~123'
        'ref ~"pr label1"'                   | 'ref parent-group-one/old-project~123'
        # group level label reference
        'ref ~321'                           | 'ref parent-group-one/old-project~321'
        'ref ~"gr label1"'                   | 'ref parent-group-one/old-project~321'
        # project level milestone reference
        'ref %"project milestone"'           | 'ref /parent-group-one/old-project%"project milestone"'
        # group level milestone reference
        'ref %"group milestone"'             | 'ref /parent-group-one%"group milestone"'
      end

      with_them do
        it_behaves_like 'rewrites references correctly'
      end
    end

    context 'with invalid references' do
      let_it_be(:source_parent) { source_project }
      let_it_be(:target_parent) { target_project1 }

      where(:text_with_reference) do
        [
          # work item references
          # project level non-existing WI references
          'ref parent-group-one/old-project#12321',
          'ref parent-group-one/old-project#12321+',
          'ref parent-group-one/old-project#12321+s',
          'ref /parent-group-one/old-project#12321',
          'ref /parent-group-one/old-project#12321+',
          'ref /parent-group-one/old-project#12321+s',

          # group level non-existing WI references
          'ref parent-group-one/old-group#12321',
          'ref parent-group-one/old-group#12321+',
          'ref parent-group-one/old-group#12321+s',
          'ref /parent-group-one/old-group#12321',
          'ref /parent-group-one/old-group#12321+',
          'ref /parent-group-one/old-group#12321+s',

          # project level non-existing design references
          'ref parent-group-one/old-project#1/designs[homescreen.jpg]',
          'ref parent-group-one/old-project#12321/designs[homescreen.jpg]',
          'ref parent-group-one/old-group#12321/designs[homescreen.jpg]',
          'ref /parent-group-one/old-project#1/designs[homescreen.jpg]',
          'ref /parent-group-one/old-project#12321/designs[homescreen.jpg]',
          'ref /parent-group-one/old-group#12321/designs[homescreen.jpg]',

          # merge request references
          # project level non-existing MR references
          'ref parent-group-one/old-project!12321',
          'ref parent-group-one/old-project!12321+',
          'ref parent-group-one/old-project!12321+s',
          'ref /parent-group-one/old-project!12321',
          'ref /parent-group-one/old-project!12321+',
          'ref /parent-group-one/old-project!12321+s',

          # root group
          'ref parent-group-one!1',
          'ref parent-group-one!1+',
          'ref parent-group-one!1+s',
          'ref /parent-group-one!1',
          'ref /parent-group-one!1+',
          'ref /parent-group-one!1+s',

          # sub-group
          'ref parent-group-one/new-group!1',
          'ref parent-group-one/new-group!1+',
          'ref parent-group-one/new-group!1+s',
          'ref /parent-group-one/new-group!1',
          'ref /parent-group-one/new-group!1+',
          'ref /parent-group-one/new-group!1+s',

          # alert reference
          'ref parent-group-one/old-project^alert#123',
          'ref parent-group-one^alert#123',
          'ref parent-group-one/new-group^alert#123',
          'ref /parent-group-one/old-project^alert#123',
          'ref /parent-group-one^alert#123',
          'ref /parent-group-one/new-group^alert#123',

          # feature flag reference
          'ref [feature_flag:parent-group-one/old-project/123]',
          'ref [feature_flag:parent-group-one/123]',
          'ref [feature_flag:parent-group-one/old-group/123]',
          'ref [feature_flag:/parent-group-one/old-project/123]',
          'ref [feature_flag:/parent-group-one/123]',
          'ref [feature_flag:/parent-group-one/old-group/123]'
        ]
      end

      with_them do
        it_behaves_like 'does not raise errors on invalid references'
      end
    end
  end
end
