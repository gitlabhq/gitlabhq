# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Gfm::ReferenceRewriter do
  let(:group) { create(:group) }
  let(:old_project) { create(:project, name: 'old-project', group: group) }
  let(:new_project) { create(:project, name: 'new-project', group: group) }
  let(:user) { create(:user) }

  let(:old_project_ref) { old_project.to_reference(new_project) }
  let(:text) { 'some text' }

  before do
    old_project.add_reporter(user)
  end

  describe '#rewrite' do
    subject do
      described_class.new(text, old_project, user).rewrite(new_project)
    end

    context 'multiple issues and merge requests referenced' do
      let!(:issue_first) { create(:issue, project: old_project) }
      let!(:issue_second) { create(:issue, project: old_project) }
      let!(:merge_request) { create(:merge_request, source_project: old_project) }

      context 'plain text description' do
        let(:text) { 'Description that references #1, #2 and !1' }

        it { is_expected.to include issue_first.to_reference(new_project) }
        it { is_expected.to include issue_second.to_reference(new_project) }
        it { is_expected.to include merge_request.to_reference(new_project) }
      end

      context 'description with ignored elements' do
        let(:text) do
          "Hi. This references #1, but not `#2`\n" +
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

        context 'description with project labels' do
          let!(:label) { create(:label, id: 123, name: 'test', project: old_project) }

          context 'label referenced by id' do
            let(:text) { '#1 and ~123' }

            it { is_expected.to eq %Q{#{old_project_ref}#1 and #{old_project_ref}~123} }
          end

          context 'label referenced by text' do
            let(:text) { '#1 and ~"test"' }

            it { is_expected.to eq %Q{#{old_project_ref}#1 and #{old_project_ref}~123} }
          end
        end

        context 'description with group labels' do
          let(:old_group) { create(:group) }
          let!(:group_label) { create(:group_label, id: 321, name: 'group label', group: old_group) }

          before do
            old_project.update(namespace: old_group)
          end

          context 'label referenced by id' do
            let(:text) { '#1 and ~321' }

            it { is_expected.to eq %Q{#{old_project_ref}#1 and #{old_project_ref}~321} }
          end

          context 'label referenced by text' do
            let(:text) { '#1 and ~"group label"' }

            it { is_expected.to eq %Q{#{old_project_ref}#1 and #{old_project_ref}~321} }
          end
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

    context 'reference contains project milestone' do
      let!(:milestone) do
        create(:milestone, title: '9.0', project: old_project)
      end

      let(:text) { 'milestone: %"9.0"' }

      it { is_expected.to eq %Q[milestone: #{old_project_ref}%"9.0"] }
    end

    context 'when referring to group milestone' do
      let!(:milestone) do
        create(:milestone, title: '10.0', group: group)
      end

      let(:text) { 'milestone %"10.0"' }

      it { is_expected.to eq text }
    end

    context 'when referable has a nil reference' do
      before do
        create(:milestone, title: '9.0', project: old_project)

        allow_any_instance_of(Milestone)
          .to receive(:to_reference)
          .and_return(nil)
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
end
