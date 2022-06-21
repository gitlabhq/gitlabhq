# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::PositionTracer::LineStrategy, :clean_gitlab_redis_cache do
  # Douwe's diary                                    New York City, 2016-06-28
  # --------------------------------------------------------------------------
  #
  # Dear diary,
  #
  # Ideally, we would have a test for every single diff scenario that can
  # occur and that the PositionTracer should correctly trace a position
  # through, across the following variables:
  #
  # - Old diff file type: created, changed, renamed, deleted, unchanged (5)
  # - Old diff line type: added, removed, unchanged (3)
  # - New diff file type: created, changed, renamed, deleted, unchanged (5)
  # - New diff line type: added, removed, unchanged (3)
  # - Old-to-new diff line change: kept, moved, undone (3)
  #
  # This adds up to 5 * 3 * 5 * 3 * 3 = 675 different potential scenarios,
  # and 675 different tests to cover them all. In reality, it would be fewer,
  # since one cannot have a removed line in a created file diff, for example,
  # but for the sake of this diary entry, let's be pessimistic.
  #
  # Writing these tests is a manual and time consuming process, as every test
  # requires the manual construction or finding of a combination of diffs that
  # create the exact diff scenario we are looking for, and can take between
  # 1 and 10 minutes, depending on the farfetchedness of the scenario and
  # complexity of creating it.
  #
  # This means that writing tests to cover all of these scenarios would end up
  # taking between 11 and 112 hours in total, which I do not believe is the
  # best use of my time.
  #
  # A better course of action would be to think of scenarios that are likely
  # to occur, but also potentially tricky to trace correctly, and only cover
  # those, with a few more obvious scenarios thrown in to cover our bases.
  #
  # Unfortunately, I only came to the above realization once I was about
  # 1/5th of the way through the process of writing ALL THE SPECS, having
  # already wasted about 3 hours trying to be thorough.
  #
  # I did find 2 bugs while writing those though, so that's good.
  #
  # In any case, all of this means that the tests below will be extremely
  # (excessively, unjustifiably) thorough for scenarios where "the file was
  # created in the old diff" and then drop off to comparatively lackluster
  # testing of other scenarios.
  #
  # I did still try to cover most of the obvious and potentially tricky
  # scenarios, though.

  include RepoHelpers
  include PositionTracerHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { project.first_owner }
  let(:repository) { project.repository }
  let(:file_name) { "test-file" }
  let(:new_file_name) { "#{file_name}-new" }
  let(:second_file_name) { "#{file_name}-2" }
  let(:branch_name) { "position-tracer-test" }

  let(:old_diff_refs) { raise NotImplementedError }
  let(:new_diff_refs) { raise NotImplementedError }
  let(:change_diff_refs) { raise NotImplementedError }
  let(:old_position) { raise NotImplementedError }

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

  describe "#trace" do
    describe "diff scenarios" do
      let(:create_file_commit) do
        initial_commit

        create_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            A
            B
            C
          CONTENT
        )
      end

      let(:create_second_file_commit) do
        create_file_commit

        create_file(
          branch_name,
          second_file_name,
          <<-CONTENT.strip_heredoc
            D
            E
          CONTENT
        )
      end

      let(:update_line_commit) do
        create_second_file_commit

        update_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            A
            BB
            C
          CONTENT
        )
      end

      let(:update_second_file_line_commit) do
        update_line_commit

        update_file(
          branch_name,
          second_file_name,
          <<-CONTENT.strip_heredoc
            D
            EE
          CONTENT
        )
      end

      let(:move_line_commit) do
        update_second_file_line_commit

        update_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            BB
            A
            C
          CONTENT
        )
      end

      let(:add_second_file_line_commit) do
        move_line_commit

        update_file(
          branch_name,
          second_file_name,
          <<-CONTENT.strip_heredoc
            D
            EE
            F
          CONTENT
        )
      end

      let(:move_second_file_line_commit) do
        add_second_file_line_commit

        update_file(
          branch_name,
          second_file_name,
          <<-CONTENT.strip_heredoc
            D
            F
            EE
          CONTENT
        )
      end

      let(:delete_line_commit) do
        move_second_file_line_commit

        update_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            BB
            A
          CONTENT
        )
      end

      let(:delete_second_file_line_commit) do
        delete_line_commit

        update_file(
          branch_name,
          second_file_name,
          <<-CONTENT.strip_heredoc
            D
            F
          CONTENT
        )
      end

      let(:delete_file_commit) do
        delete_second_file_line_commit

        delete_file(branch_name, file_name)
      end

      let(:rename_file_commit) do
        delete_file_commit

        create_file(
          branch_name,
          new_file_name,
          <<-CONTENT.strip_heredoc
            BB
            A
          CONTENT
        )
      end

      let(:update_line_again_commit) do
        rename_file_commit

        update_file(
          branch_name,
          new_file_name,
          <<-CONTENT.strip_heredoc
            BB
            AA
          CONTENT
        )
      end

      let(:move_line_again_commit) do
        update_line_again_commit

        update_file(
          branch_name,
          new_file_name,
          <<-CONTENT.strip_heredoc
            AA
            BB
          CONTENT
        )
      end

      let(:delete_line_again_commit) do
        move_line_again_commit

        update_file(
          branch_name,
          new_file_name,
          <<-CONTENT.strip_heredoc
            AA
          CONTENT
        )
      end

      context "when the file was created in the old diff" do
        context "when the file is created in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
              let(:new_diff_refs) { diff_refs(initial_commit, create_second_file_commit) }
              let(:old_position) { position(new_path: file_name, new_line: 2) }

              # old diff:
              #   1 + A
              #   2 + B
              #   3 + C
              #
              # new diff:
              #   1 + A
              #   2 + B
              #   3 + C

              it "returns the new position" do
                expect_new_position(
                  new_path: old_position.new_path,
                  new_line: old_position.new_line
                )
              end

              context "when the position is multiline" do
                let(:old_position) do
                  position(
                    new_path: file_name,
                    new_line: 2,
                    line_range: {
                      "start" => {
                        "line_code" => 1
                      },
                      "end" => {
                        "line_code" => 2
                      }
                    }
                  )
                end

                it "returns the new position along with line_range" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    new_line: old_position.new_line,
                    line_range: old_position.line_range
                  )
                end
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                #   1 + A
                #   2 + BB
                #   3 + C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    new_line: old_position.new_line
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                #   1 + BB
                #   2 + A
                #   3 + C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:change_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                #   1 + A
                #   2 + BB
                #   3 + C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
                let(:change_diff_refs) { diff_refs(update_line_commit, delete_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 3) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                #   1 + A
                #   2 + BB

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 3,
                    new_line: nil
                  )
                end
              end
            end
          end
        end

        context "when the file is changed in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
              let(:new_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
              let(:old_position) { position(new_path: file_name, new_line: 1) }

              # old diff:
              #   1 + A
              #   2 + BB
              #   3 + C
              #
              # new diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C

              it "returns the new position" do
                expect_new_position(
                  new_path: old_position.new_path,
                  new_line: old_position.new_line
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, move_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 3) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                # 1   - A
                # 2 1   BB
                #   2 + A
                # 3 3   C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    new_line: old_position.new_line
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, move_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                # 1   - A
                # 2 1   BB
                #   2 + A
                # 3 3   C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:change_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                # 1 1   A
                # 2   - B
                #   2 + BB
                # 3 3   C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(move_line_commit, delete_line_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, delete_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 3) }

                # old diff:
                #   1 + BB
                #   2 + A
                #   3 + C
                #
                # new diff:
                # 1 1   BB
                # 2 2   A
                # 3   - C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 3,
                    new_line: nil
                  )
                end
              end
            end
          end
        end

        context "when the file is renamed in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
              let(:new_diff_refs) { diff_refs(delete_line_commit, rename_file_commit) }
              let(:change_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
              let(:old_position) { position(new_path: file_name, new_line: 2) }

              # old diff:
              #   1 + BB
              #   2 + A
              #
              # new diff:
              # file_name -> new_file_name
              # 1 1   BB
              # 2 2   A

              it "returns the position of the change" do
                expect_change_position(
                  old_path: file_name,
                  new_path: file_name,
                  old_line: nil,
                  new_line: 2
                )
              end

              context "when the position is multiline" do
                let(:old_position) do
                  position(
                    new_path: file_name,
                    new_line: 2,
                    line_range: {
                      "start" => {
                        "line_code" => 1
                      },
                      "end" => {
                        "line_code" => 2
                      }
                    }
                  )
                end

                it "returns the new position" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: nil,
                    new_line: 2,
                    line_range: {
                      "start" => {
                        "line_code" => 1
                      },
                      "end" => {
                        "line_code" => 2
                      }
                    }
                  )
                end
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, update_line_again_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                #   2 + A
                #
                # new diff:
                # file_name -> new_file_name
                # 1 1   BB
                # 2   - A
                #   2 + AA

                it "returns the new position" do
                  expect_new_position(
                    old_path: file_name,
                    new_path: new_file_name,
                    old_line: old_position.new_line,
                    new_line: old_position.new_line
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, move_line_again_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                #   2 + A
                #
                # new diff:
                # file_name -> new_file_name
                #   1 + AA
                # 1 2   BB
                # 2   - A

                it "returns the new position" do
                  expect_new_position(
                    old_path: file_name,
                    new_path: new_file_name,
                    old_line: 1,
                    new_line: 2
                  )
                end
              end

              context "when that line was changed between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, update_line_again_commit) }
                let(:change_diff_refs) { diff_refs(delete_line_commit, update_line_again_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + BB
                #   2 + A
                #
                # new diff:
                # file_name -> new_file_name
                # 1 1   BB
                # 2   - A
                #   2 + AA

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: new_file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end
            end
          end
        end

        context "when the file is deleted in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
              let(:new_diff_refs) { diff_refs(delete_line_commit, delete_file_commit) }
              let(:change_diff_refs) { diff_refs(delete_line_commit, delete_file_commit) }
              let(:old_position) { position(new_path: file_name, new_line: 2) }

              # old diff:
              #   1 + BB
              #   2 + A
              #
              # new diff:
              # 1   - BB
              # 2   - A

              it "returns the position of the change" do
                expect_change_position(
                  old_path: file_name,
                  new_path: file_name,
                  old_line: 2,
                  new_line: nil
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, delete_file_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, delete_file_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + BB
                #   2 + A
                #   3 + C
                #
                # new diff:
                # 1   - BB
                # 2   - A

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(move_line_commit, delete_file_commit) }
                let(:change_diff_refs) { diff_refs(update_line_commit, delete_file_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                # 1   - BB
                # 2   - A
                # 3   - C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was changed between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, delete_file_commit) }
                let(:change_diff_refs) { diff_refs(create_file_commit, delete_file_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                # 1   - A
                # 2   - BB
                # 3   - C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, delete_file_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, delete_file_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 3) }

                # old diff:
                #   1 + BB
                #   2 + A
                #   3 + C
                #
                # new diff:
                # 1   - BB
                # 2   - A

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 3,
                    new_line: nil
                  )
                end
              end
            end
          end
        end

        context "when the file is unchanged in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
              let(:new_diff_refs) { diff_refs(create_file_commit, create_second_file_commit) }
              let(:change_diff_refs) { diff_refs(initial_commit, create_file_commit) }
              let(:old_position) { position(new_path: file_name, new_line: 2) }

              # old diff:
              #   1 + A
              #   2 + B
              #   3 + C
              #
              # new diff:
              # 1 1   A
              # 2 2   B
              # 3 3   C

              it "returns the position of the change" do
                expect_change_position(
                  old_path: file_name,
                  new_path: file_name,
                  old_line: nil,
                  new_line: 2
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, update_second_file_line_commit) }
                let(:change_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                # 1 1   A
                # 2 2   BB
                # 3 3   C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: nil,
                    new_line: 1
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(move_line_commit, move_second_file_line_commit) }
                let(:change_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + BB
                #   3 + C
                #
                # new diff:
                # 1 1   BB
                # 2 2   A
                # 3 3   C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: nil,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, update_second_file_line_commit) }
                let(:change_diff_refs) { diff_refs(create_file_commit, update_second_file_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 2) }

                # old diff:
                #   1 + A
                #   2 + B
                #   3 + C
                #
                # new diff:
                # 1 1   A
                # 2 2   BB
                # 3 3   C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 2,
                    new_line: nil
                  )
                end
              end

              context "when that line was deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(delete_line_commit, delete_second_file_line_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, delete_second_file_line_commit) }
                let(:old_position) { position(new_path: file_name, new_line: 3) }

                # old diff:
                #   1 + BB
                #   2 + A
                #   3 + C
                #
                # new diff:
                # 1 1   BB
                # 2 2   A

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 3,
                    new_line: nil
                  )
                end
              end
            end
          end
        end
      end

      context "when the file was changed in the old diff" do
        context "when the file is created in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
              let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
              let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 2) }

              # old diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C
              #
              # new diff:
              #   1 + A
              #   2 + BB
              #   3 + C

              it "returns the new position" do
                expect_new_position(
                  new_path: old_position.new_path,
                  old_line: nil,
                  new_line: old_position.new_line
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                #   1 + BB
                #   2 + A

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    old_line: nil,
                    new_line: old_position.new_line
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 2) }

                # old diff:
                # 1 1   A
                # 2   - B
                #   2 + BB
                # 3 3   C
                #
                # new diff:
                #   1 + BB
                #   2 + A
                #   3 + C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    old_line: nil,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed or deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, create_file_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, create_file_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                #   1 + A
                #   2 + B
                #   3 + C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 1,
                    new_line: nil
                  )
                end
              end
            end
          end

          context "when the position pointed at a deleted line in the old diff" do
            let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
            let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
            let(:change_diff_refs) { diff_refs(create_file_commit, initial_commit) }
            let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 2) }

            # old diff:
            # 1 1   A
            # 2   - B
            #   2 + BB
            # 3 3   C
            #
            # new diff:
            #   1 + A
            #   2 + BB
            #   3 + C

            it "returns the position of the change" do
              expect_change_position(
                old_path: file_name,
                new_path: file_name,
                old_line: 2,
                new_line: nil
              )
            end
          end

          context "when the position pointed at an unchanged line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
              let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
              let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 1, new_line: 1) }

              # old diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C
              #
              # new diff:
              #   1 + A
              #   2 + BB
              #   3 + C

              it "returns the new position" do
                expect_new_position(
                  new_path: old_position.new_path,
                  old_line: nil,
                  new_line: old_position.new_line
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, move_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 1, new_line: 2) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                #   1 + BB
                #   2 + A

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    old_line: nil,
                    new_line: old_position.new_line
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(move_line_commit, delete_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, update_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 2, new_line: 2) }

                # old diff:
                # 1 1   BB
                # 2 2   A
                # 3   - C
                #
                # new diff:
                #   1 + A
                #   2 + BB
                #   3 + C

                it "returns the new position" do
                  expect_new_position(
                    new_path: old_position.new_path,
                    old_line: nil,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed or deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(initial_commit, delete_line_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, delete_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 3, new_line: 3) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                #   1 + A
                #   2 + B

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 3,
                    new_line: nil
                  )
                end
              end
            end
          end
        end

        context "when the file is changed in the new diff" do
          context "when the position pointed at an added line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
              let(:new_diff_refs) { diff_refs(create_file_commit, update_second_file_line_commit) }
              let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 2) }

              # old diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C
              #
              # new diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C

              it "returns the new position" do
                expect_new_position(
                  old_path: old_position.old_path,
                  new_path: old_position.new_path,
                  old_line: nil,
                  new_line: old_position.new_line
                )
              end
            end

            context "when the file's content was changed between the old and the new diff" do
              context "when that line was unchanged between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(move_line_commit, delete_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                # 1 1   BB
                # 2 2   A
                # 3   - C

                it "returns the new position" do
                  expect_new_position(
                    old_path: old_position.old_path,
                    new_path: old_position.new_path,
                    old_line: 1,
                    new_line: 1
                  )
                end
              end

              context "when that line was moved between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:new_diff_refs) { diff_refs(update_line_commit, move_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 2) }

                # old diff:
                # 1 1   A
                # 2   - B
                #   2 + BB
                # 3 3   C
                #
                # new diff:
                # 1   - A
                # 2 1   BB
                #   2 + A
                # 3 3   C

                it "returns the new position" do
                  expect_new_position(
                    old_path: old_position.old_path,
                    new_path: old_position.new_path,
                    old_line: 2,
                    new_line: 1
                  )
                end
              end

              context "when that line was changed or deleted between the old and the new diff" do
                let(:old_diff_refs) { diff_refs(create_file_commit, move_line_commit) }
                let(:new_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
                let(:change_diff_refs) { diff_refs(move_line_commit, update_line_commit) }
                let(:old_position) { position(old_path: file_name, new_path: file_name, new_line: 1) }

                # old diff:
                #   1 + BB
                # 1 2   A
                # 2   - B
                # 3 3   C
                #
                # new diff:
                # 1 1   A
                # 2   - B
                #   2 + BB
                # 3 3   C

                it "returns the position of the change" do
                  expect_change_position(
                    old_path: file_name,
                    new_path: file_name,
                    old_line: 1,
                    new_line: nil
                  )
                end
              end
            end
          end

          context "when the position pointed at a deleted line in the old diff" do
            context "when the file's content was unchanged between the old and the new diff" do
              let(:old_diff_refs) { diff_refs(create_file_commit, update_line_commit) }
              let(:new_diff_refs) { diff_refs(create_file_commit, update_second_file_line_commit) }
              let(:old_position) { position(old_path: file_name, new_path: file_name, old_line: 2) }

              # old diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C
              #
              # new diff:
              # 1 1   A
              # 2   - B
              #   2 + BB
              # 3 3   C

              it "returns the new position" do
                expect_new_position(
                  old_path: old_position.old_path,
                  new_path: old_position.new_path,
                  old_line: old_position.old_line,
                  new_line: nil
                )
              end
            end
          end
        end
      end
    end

    describe "typical use scenarios" do
      let(:second_branch_name) { "#{branch_name}-2" }

      def expect_new_positions(old_attrs, new_attrs)
        old_positions = old_attrs.map do |old_attrs|
          position(old_attrs)
        end

        new_positions = old_positions.map do |old_position|
          strategy.trace(old_position)
        end

        aggregate_failures do
          new_positions.zip(new_attrs).each do |new_position, new_attrs|
            if new_attrs&.delete(:change)
              expect_change_position(new_attrs, new_position)
            else
              expect_new_position(new_attrs, new_position)
            end
          end
        end
      end

      let(:create_file_commit) do
        initial_commit

        create_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            A
            B
            C
            D
            E
            F
          CONTENT
        )
      end

      let(:second_create_file_commit) do
        create_file_commit

        create_branch(second_branch_name, branch_name)

        update_file(
          second_branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            Z
            Z
            Z
            A
            B
            C
            D
            E
            F
          CONTENT
        )
      end

      let(:update_file_commit) do
        second_create_file_commit

        update_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            A
            C
            DD
            E
            F
            G
          CONTENT
        )
      end

      let(:update_file_again_commit) do
        update_file_commit

        update_file(
          branch_name,
          file_name,
          <<-CONTENT.strip_heredoc
            A
            BB
            C
            D
            E
            FF
            G
          CONTENT
        )
      end

      describe "simple push of new commit" do
        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
        let(:new_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
        let(:change_diff_refs) { diff_refs(update_file_commit, update_file_again_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        # 3 2   C
        # 4   - D
        #   3 + DD
        # 5 4   E
        # 6 5   F
        #   6 + G
        #
        # new diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 2 }, #   C
            { old_path: file_name,                      old_line: 4              }, # - D
            {                      new_path: file_name,              new_line: 3 }, # + DD
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 4 }, #   E
            { old_path: file_name, new_path: file_name, old_line: 6, new_line: 5 }, #   F
            {                      new_path: file_name,              new_line: 6 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 },
            { old_path: file_name,                      old_line: 2              },
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 },
            {                      new_path: file_name,              new_line: 4,   change: true },
            {                      new_path: file_name, old_line: 3,                change: true },
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 },
            {                      new_path: file_name, old_line: 5, change: true },
            {                      new_path: file_name, new_line: 7 }
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end

      describe "force push to overwrite last commit" do
        let(:second_create_file_commit) do
          create_file_commit

          create_branch(second_branch_name, branch_name)

          update_file(
            second_branch_name,
            file_name,
            <<-CONTENT.strip_heredoc
              A
              BB
              C
              D
              E
              FF
              G
            CONTENT
          )
        end

        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
        let(:new_diff_refs) { diff_refs(create_file_commit, second_create_file_commit) }
        let(:change_diff_refs) { diff_refs(update_file_commit, second_create_file_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        # 3 2   C
        # 4   - D
        #   3 + DD
        # 5 4   E
        # 6 5   F
        #   6 + G
        #
        # new diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 2 }, #   C
            { old_path: file_name,                      old_line: 4              }, # - D
            {                      new_path: file_name,              new_line: 3 }, # + DD
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 4 }, #   E
            { old_path: file_name, new_path: file_name, old_line: 6, new_line: 5 }, #   F
            {                      new_path: file_name,              new_line: 6 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 },
            { old_path: file_name,                      old_line: 2              },
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 },
            {                      new_path: file_name,              new_line: 4,   change: true },
            { old_path: file_name,                      old_line: 3,                change: true },
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 },
            { old_path: file_name,                      old_line: 5, change: true },
            {                      new_path: file_name,              new_line: 7 }
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end

      describe "force push to delete last commit" do
        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
        let(:new_diff_refs) { diff_refs(create_file_commit, update_file_commit) }
        let(:change_diff_refs) { diff_refs(update_file_again_commit, update_file_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G
        #
        # new diff:
        # 1 1   A
        # 2   - B
        # 3 2   C
        # 4   - D
        #   3 + DD
        # 5 4   E
        # 6 5   F
        #   6 + G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 2 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 4 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 6 }, # + FF
            {                      new_path: file_name,              new_line: 7 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 },
            { old_path: file_name,                      old_line: 2              },
            { old_path: file_name,                      old_line: 2, change: true },
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 2 },
            { old_path: file_name,                      old_line: 4, change: true },
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 4 },
            {                      new_path: file_name,              new_line: 5, change: true },
            { old_path: file_name, old_line: 6, change: true },
            { new_path: file_name, new_line: 6 }
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end

      describe "rebase on top of target branch" do
        let(:second_update_file_commit) do
          update_file_commit

          update_file(
            second_branch_name,
            file_name,
            <<-CONTENT.strip_heredoc
              Z
              Z
              Z
              A
              C
              DD
              E
              F
              G
            CONTENT
          )
        end

        let(:update_file_again_commit) do
          second_update_file_commit

          update_file(
            branch_name,
            file_name,
            <<-CONTENT.strip_heredoc
              A
              BB
              C
              D
              E
              FF
              G
            CONTENT
          )
        end

        let(:overwrite_update_file_again_commit) do
          update_file_again_commit

          update_file(
            second_branch_name,
            file_name,
            <<-CONTENT.strip_heredoc
              Z
              Z
              Z
              A
              BB
              C
              D
              E
              FF
              G
            CONTENT
          )
        end

        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
        let(:new_diff_refs) { diff_refs(create_file_commit, overwrite_update_file_again_commit) }
        let(:change_diff_refs) { diff_refs(update_file_again_commit, overwrite_update_file_again_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G
        #
        # new diff:
        #   1 + Z
        #   2 + Z
        #   3 + Z
        # 1 4   A
        # 2   - B
        #   5 + BB
        # 3 6   C
        # 4 7   D
        # 5 8   E
        # 6   - F
        #   9 + FF
        #   0 + G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 2 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 4 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 6 }, # + FF
            {                      new_path: file_name,              new_line: 7 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 4 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 5 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 6 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 7 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 8 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 9 }, # + FF
            {                      new_path: file_name,              new_line: 10 } # + G
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end

      describe "merge of target branch" do
        let(:merge_commit) do
          second_create_file_commit

          merge_request = create(:merge_request, source_branch: second_branch_name, target_branch: branch_name, source_project: project)

          repository.merge(current_user, merge_request.diff_head_sha, merge_request, "Merge branches")

          project.commit(branch_name)
        end

        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
        let(:new_diff_refs) { diff_refs(create_file_commit, merge_commit) }
        let(:change_diff_refs) { diff_refs(update_file_again_commit, merge_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G
        #
        # new diff:
        #   1 + Z
        #   2 + Z
        #   3 + Z
        # 1 4   A
        # 2   - B
        #   5 + BB
        # 3 6   C
        # 4 7   D
        # 5 8   E
        # 6   - F
        #   9 + FF
        #   0 + G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 2 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 4 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 6 }, # + FF
            {                      new_path: file_name,              new_line: 7 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 4 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 5 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 6 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 7 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 8 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 9 }, # + FF
            {                      new_path: file_name,              new_line: 10 } # + G
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end

      describe "changing target branch" do
        let(:old_diff_refs) { diff_refs(create_file_commit, update_file_again_commit) }
        let(:new_diff_refs) { diff_refs(update_file_commit, update_file_again_commit) }
        let(:change_diff_refs) { diff_refs(create_file_commit, update_file_commit) }

        # old diff:
        # 1 1   A
        # 2   - B
        #   2 + BB
        # 3 3   C
        # 4 4   D
        # 5 5   E
        # 6   - F
        #   6 + FF
        #   7 + G
        #
        # new diff:
        # 1 1   A
        #   2 + BB
        # 2 3   C
        # 3   - DD
        #   4 + D
        # 4 5   E
        # 5   - F
        #   6 + FF
        #   7   G

        it "returns the new positions" do
          old_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 }, #   A
            { old_path: file_name,                      old_line: 2              }, # - B
            {                      new_path: file_name,              new_line: 2 }, # + BB
            { old_path: file_name, new_path: file_name, old_line: 3, new_line: 3 }, #   C
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 4 }, #   D
            { old_path: file_name, new_path: file_name, old_line: 5, new_line: 5 }, #   E
            { old_path: file_name,                      old_line: 6              }, # - F
            {                      new_path: file_name,              new_line: 6 }, # + FF
            {                      new_path: file_name,              new_line: 7 } # + G
          ]

          new_position_attrs = [
            { old_path: file_name, new_path: file_name, old_line: 1, new_line: 1 },
            { old_path: file_name,                      old_line: 2, change: true },
            {                      new_path: file_name,              new_line: 2 },
            { old_path: file_name, new_path: file_name, old_line: 2, new_line: 3 },
            {                      new_path: file_name,              new_line: 4 },
            { old_path: file_name, new_path: file_name, old_line: 4, new_line: 5 },
            { old_path: file_name,                      old_line: 5              },
            {                      new_path: file_name,              new_line: 6 },
            {                      new_path: file_name,              new_line: 7 }
          ]

          expect_new_positions(old_position_attrs, new_position_attrs)
        end
      end
    end
  end
end
