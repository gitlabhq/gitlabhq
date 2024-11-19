# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::CommitService, feature_category: :code_review_workflow do
  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }

  let(:commit_service) { described_class.new(noteable: noteable, container: project, author: author) }

  describe '#add_commits' do
    subject { commit_service.add_commits(new_commits, old_commits, oldrev) }

    let(:noteable)    { create(:merge_request, source_project: project, target_project: project) }
    let(:new_commits) { create_commits(10) }
    let(:old_commits) { [] }
    let(:oldrev)      { nil }

    it_behaves_like 'a system note' do
      let(:commit_count) { new_commits.size }
      let(:action)       { 'commit' }
    end

    describe 'note body' do
      let(:note_lines) { subject.note.split("\n").reject(&:blank?) }

      describe 'comparison diff link line' do
        it 'adds the comparison text' do
          expect(note_lines[2]).to match "[Compare with previous version]"
        end
      end

      context 'without existing commits' do
        it 'adds a message header' do
          expect(note_lines[0]).to eq "added #{new_commits.size} commits"
        end

        it 'adds a message for each commit' do
          decoded_note_content = HTMLEntities.new.decode(subject.note)

          new_commits.each do |commit|
            expect(decoded_note_content).to include("<li>#{commit.short_id} - #{commit.title}</li>")
          end
        end

        context 'with HTML content' do
          let(:new_commits) { [double(title: '<pre>This is a test</pre>', short_id: '12345678')] }

          it 'escapes HTML titles' do
            expect(note_lines[1]).to eq("<ul><li>12345678 - &lt;pre&gt;This is a test&lt;/pre&gt;</li></ul>")
          end
        end

        context 'with one commit exceeding the NEW_COMMIT_DISPLAY_LIMIT' do
          let(:new_commits) { create_commits(11) }
          let(:earlier_commit_summary_line) { note_lines[1] }

          it 'includes the truncated new commits summary' do
            expect(earlier_commit_summary_line).to start_with("<ul><li>#{new_commits[0].short_id} - 1 earlier commit")
          end

          context 'with oldrev' do
            let(:oldrev) { '12345678abcd' }

            it 'includes the truncated new commits summary with the oldrev' do
              expect(earlier_commit_summary_line).to start_with("<ul><li>#{new_commits[0].short_id} - 1 earlier commit")
            end
          end
        end

        context 'with multiple commits exceeding the NEW_COMMIT_DISPLAY_LIMIT' do
          let(:new_commits) { create_commits(13) }
          let(:earlier_commit_summary_line) { note_lines[1] }

          it 'includes the truncated new commits summary' do
            expect(earlier_commit_summary_line).to start_with("<ul><li>#{new_commits[0].short_id}..#{new_commits[2].short_id} - 3 earlier commits")
          end

          context 'with oldrev' do
            let(:oldrev) { '12345678abcd' }

            it 'includes the truncated new commits summary with the oldrev' do
              expect(earlier_commit_summary_line).to start_with("<ul><li>12345678...#{new_commits[2].short_id} - 3 earlier commits")
            end
          end
        end
      end

      describe 'summary line for existing commits' do
        let(:summary_line) { note_lines[1] }

        context 'with one existing commit' do
          let(:old_commits) { [noteable.commits.last] }

          it 'includes the existing commit' do
            expect(summary_line).to start_with("<ul><li>#{old_commits.first.short_id} - 1 commit from branch <code>feature</code>")
          end

          context 'with new commits exceeding the display limit' do
            let(:summary_line) { note_lines[1] }
            let(:new_commits) { create_commits(13) }

            it 'includes the existing commit as well as the truncated new commit summary' do
              expect(summary_line).to start_with("<ul><li>#{old_commits.first.short_id} - 1 commit from branch <code>feature</code></li><li>#{old_commits.last.short_id}...#{new_commits[2].short_id} - 3 earlier commits")
            end
          end
        end

        context 'with multiple existing commits' do
          let(:old_commits) { noteable.commits[3..] }

          context 'with oldrev' do
            let(:oldrev) { noteable.commits[2].id }

            it 'includes a commit range and count' do
              expect(summary_line)
                .to start_with("<ul><li>#{Commit.truncate_sha(oldrev)}...#{old_commits.last.short_id} - 26 commits from branch <code>feature</code>")
            end

            context 'with new commits exceeding the display limit' do
              let(:new_commits) { create_commits(13) }

              it 'includes the existing commit as well as the truncated new commit summary' do
                expect(summary_line)
                  .to start_with("<ul><li>#{Commit.truncate_sha(oldrev)}...#{old_commits.last.short_id} - 26 commits from branch <code>feature</code></li><li>#{old_commits.last.short_id}...#{new_commits[2].short_id} - 3 earlier commits")
              end
            end
          end

          context 'without oldrev' do
            it 'includes a commit range and count' do
              expect(summary_line)
                .to start_with("<ul><li>#{old_commits[0].short_id}..#{old_commits[-1].short_id} - 26 commits from branch <code>feature</code>")
            end

            context 'with new commits exceeding the display limit' do
              let(:new_commits) { create_commits(13) }

              it 'includes the existing commit as well as the truncated new commit summary' do
                expect(summary_line)
                  .to start_with("<ul><li>#{old_commits.first.short_id}..#{old_commits.last.short_id} - 26 commits from branch <code>feature</code></li><li>#{old_commits.last.short_id}...#{new_commits[2].short_id} - 3 earlier commits")
              end
            end
          end

          context 'on a fork' do
            before do
              expect(noteable).to receive(:for_fork?).and_return(true)
            end

            it 'includes the project namespace' do
              expect(summary_line).to include("<code>#{noteable.target_project_namespace}:feature</code>")
            end
          end
        end
      end
    end
  end

  describe '#tag_commit' do
    let(:noteable) { project.commit }
    let(:tag_name) { 'v1.2.3' }

    subject { commit_service.tag_commit(tag_name) }

    it_behaves_like 'a system note' do
      let(:action) { 'tag' }
    end

    it 'sets the note text' do
      link = "/#{project.full_path}/-/tags/#{tag_name}"

      expect(subject.note).to eq "tagged commit #{noteable.sha} to [`#{tag_name}`](#{link})"
    end
  end

  def create_commits(count)
    Array.new(count) do |i|
      double(title: "Test commit #{i}", short_id: "abcd00#{i}")
    end
  end
end
