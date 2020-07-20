# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::PositionTracer::ImageStrategy do
  include PositionTracerHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { project.owner }
  let(:file_name) { 'test-file' }
  let(:new_file_name) { "#{file_name}-new" }
  let(:second_file_name) { "#{file_name}-2" }
  let(:branch_name) { 'position-tracer-test' }
  let(:old_position) { position(old_path: file_name, new_path: file_name, position_type: 'image') }

  let(:tracer) do
    Gitlab::Diff::PositionTracer.new(
      project: project,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs
    )
  end

  let(:strategy) { described_class.new(tracer) }

  subject { strategy.trace(old_position) }

  let(:initial_commit) do
    project.commit(create_branch(branch_name, 'master')[:branch].name)
  end

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

    describe 'symlink scenarios' do
      let(:new_file) { old_file_status == :new }
      let(:deleted_file) { old_file_status == :deleted }
      let(:renamed_file) { old_file_status == :renamed }

      let(:file_identifier) { "#{file_name}-#{new_file}-#{deleted_file}-#{renamed_file}" }
      let(:file_identifier_hash) { Digest::SHA1.hexdigest(file_identifier) }
      let(:old_position) { position(old_path: file_name, new_path: file_name, position_type: 'image', file_identifier_hash: file_identifier_hash) }

      let(:update_file_commit) do
        initial_commit

        update_file(
          branch_name,
          file_name,
          Base64.encode64('morecontent')
        )
      end

      let(:delete_file_commit) do
        initial_commit

        delete_file(branch_name, file_name)
      end

      let(:create_second_file_commit) do
        initial_commit

        create_file(
          branch_name,
          second_file_name,
          Base64.encode64('morecontent')
        )
      end

      before do
        stub_feature_flags(file_identifier_hash: true)
      end

      describe 'from symlink to image' do
        let(:initial_commit) { project.commit('a19c7f9a147e35e535c797cf148d29c24dac5544') }
        let(:symlink_to_image_commit) { project.commit('8cfca8420812e5bd7479aa32cf33e0c95a3ca576') }
        let(:branch_name) { 'diff-files-symlink-to-image' }
        let(:file_name) { 'symlink-to-image.png' }

        context "when the old position is on the new image file" do
          let(:old_file_status) { :new }

          context "when the image file's content was unchanged between the old and the new diff" do
            let(:old_diff_refs) { diff_refs(initial_commit, symlink_to_image_commit) }
            let(:new_diff_refs) { diff_refs(initial_commit, create_second_file_commit) }

            it "returns the new position" do
              expect_new_position(
                old_path: file_name,
                new_path: file_name
              )
            end
          end

          context "when the image file's content was changed between the old and the new diff" do
            let(:old_diff_refs) { diff_refs(initial_commit, symlink_to_image_commit) }
            let(:new_diff_refs) { diff_refs(initial_commit, update_file_commit) }
            let(:change_diff_refs) { diff_refs(symlink_to_image_commit, update_file_commit) }

            it "returns the position of the change" do
              expect_change_position(
                old_path: file_name,
                new_path: file_name
              )
            end
          end

          context "when the image file was removed between the old and the new diff" do
            let(:old_diff_refs) { diff_refs(initial_commit, symlink_to_image_commit) }
            let(:new_diff_refs) { diff_refs(initial_commit, delete_file_commit) }
            let(:change_diff_refs) { diff_refs(symlink_to_image_commit, delete_file_commit) }

            it "returns the position of the change" do
              expect_change_position(
                old_path: file_name,
                new_path: file_name
              )
            end
          end
        end
      end

      describe 'from image to symlink' do
        let(:initial_commit) { project.commit('d10dcdfbbb2b59a959a5f5d66a4adf28f0ea4008') }
        let(:image_to_symlink_commit) { project.commit('3e94fdaa60da8aed38401b91bc56be70d54ca424') }
        let(:branch_name) { 'diff-files-image-to-symlink' }
        let(:file_name) { 'image-to-symlink.png' }

        context "when the old position is on the added image file" do
          let(:old_file_status) { :new }

          context "when the image file gets changed to a symlink between the old and the new diff" do
            let(:old_diff_refs) { diff_refs(initial_commit.parent, initial_commit) }
            let(:new_diff_refs) { diff_refs(initial_commit.parent, image_to_symlink_commit) }
            let(:change_diff_refs) { diff_refs(initial_commit, image_to_symlink_commit) }

            it "returns the position of the change" do
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
end
