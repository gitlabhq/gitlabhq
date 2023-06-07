# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::PositionTracer::FileStrategy, feature_category: :code_review_workflow do
  include PositionTracerHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:current_user) { project.first_owner }
  let(:file_name) { 'test-file' }
  let(:new_file_name) { "#{file_name}-new" }
  let(:second_file_name) { "#{file_name}-2" }
  let(:branch_name) { 'position-tracer-test' }
  let(:old_position) { position(old_path: file_name, new_path: file_name, position_type: 'file') }

  let(:tracer) do
    Gitlab::Diff::PositionTracer.new(
      project: project,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs
    )
  end

  let(:strategy) { described_class.new(tracer) }

  let(:initial_commit) do
    project.commit(create_branch(branch_name, 'master')[:branch]&.name || 'master')
  end

  subject { strategy.trace(old_position) }

  describe '#trace' do
    describe 'diff scenarios' do
      let(:create_file_commit) do
        initial_commit

        create_file(
          branch_name,
          file_name,
          Base64.encode64('content')
        )
      end

      let(:update_file_commit) do
        create_file_commit

        update_file(
          branch_name,
          file_name,
          Base64.encode64('updatedcontent')
        )
      end

      let(:update_file_again_commit) do
        update_file_commit

        update_file(
          branch_name,
          file_name,
          Base64.encode64('updatedcontentagain')
        )
      end

      let(:delete_file_commit) do
        create_file_commit
        delete_file(branch_name, file_name)
      end

      let(:rename_file_commit) do
        delete_file_commit

        create_file(
          branch_name,
          new_file_name,
          Base64.encode64('renamedcontent')
        )
      end

      let(:create_second_file_commit) do
        create_file_commit

        create_file(
          branch_name,
          second_file_name,
          Base64.encode64('morecontent')
        )
      end

      let(:create_another_file_commit) do
        create_file(
          branch_name,
          second_file_name,
          Base64.encode64('morecontent')
        )
      end

      let(:update_another_file_commit) do
        update_file(
          branch_name,
          second_file_name,
          Base64.encode64('updatedmorecontent')
        )
      end

      context 'when the file was created in the old diff' do
        context 'when the file is unchanged between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
          let(:new_diff_refs) { diff_refs(initial_commit, create_second_file_commit) }

          it 'returns the new position' do
            expect_new_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was updated between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
          let(:new_diff_refs) { diff_refs(initial_commit, update_file_commit) }
          let(:change_diff_refs) { diff_refs(create_file_commit, update_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was renamed in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
          let(:new_diff_refs) { diff_refs(initial_commit, rename_file_commit) }
          let(:change_diff_refs) { diff_refs(create_file_commit, rename_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was removed in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
          let(:new_diff_refs) { diff_refs(initial_commit, delete_file_commit) }
          let(:change_diff_refs) { diff_refs(create_file_commit, delete_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file is unchanged in the new diff' do
          let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
          let(:new_diff_refs) { diff_refs(create_another_file_commit, update_another_file_commit) }
          let(:change_diff_refs) { diff_refs(initial_commit, create_another_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end
      end

      context 'when the file was changed in the old diff' do
        context 'when the file is unchanged in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
          let(:new_diff_refs) { diff_refs(create_file_commit, create_second_file_commit) }

          it 'returns the new position' do
            expect_new_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was updated in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
          let(:new_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
          let(:change_diff_refs) { diff_refs(update_file_commit, update_file_again_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was renamed in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
          let(:new_diff_refs) { diff_refs(create_file_commit, rename_file_commit) }
          let(:change_diff_refs) { diff_refs(update_file_commit, rename_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file was removed in between the old and the new diff' do
          let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
          let(:new_diff_refs) { diff_refs(create_file_commit, delete_file_commit) }
          let(:change_diff_refs) { diff_refs(update_file_commit, delete_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end

        context 'when the file is unchanged in the new diff' do
          let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
          let(:new_diff_refs) { diff_refs(create_another_file_commit, update_another_file_commit) }
          let(:change_diff_refs) { diff_refs(create_file_commit, create_another_file_commit) }

          it 'returns the position of the change' do
            expect_change_position(
              old_path: file_name,
              new_path: file_name
            )
          end
        end
      end
    end
  end
end
