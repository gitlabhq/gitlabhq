# frozen_string_literal: true

module PositionTracerHelpers
  def diff_refs(base_commit, head_commit)
    Gitlab::Diff::DiffRefs.new(base_sha: base_commit.id, head_sha: head_commit.id)
  end

  def position(attrs = {})
    attrs.reverse_merge!(
      diff_refs: old_diff_refs
    )
    Gitlab::Diff::Position.new(attrs)
  end

  def expect_new_position(attrs, result = subject)
    aggregate_failures("expect new position #{attrs.inspect}") do
      if attrs.nil?
        expect(result[:outdated]).to be_truthy
      else
        new_position = result[:position]

        expect(result[:outdated]).to be_falsey
        expect(new_position).not_to be_nil
        expect(new_position.diff_refs).to eq(new_diff_refs)

        attrs.each do |attr, value|
          expect(new_position.send(attr)).to eq(value)
        end
      end
    end
  end

  def expect_change_position(attrs, result = subject)
    aggregate_failures("expect change position #{attrs.inspect}") do
      change_position = result[:position]

      expect(result[:outdated]).to be_truthy

      if attrs.nil? || attrs.empty?
        expect(change_position).to be_nil
      else
        expect(change_position).not_to be_nil
        expect(change_position.diff_refs).to eq(change_diff_refs)

        attrs.each do |attr, value|
          expect(change_position.send(attr)).to eq(value)
        end
      end
    end
  end

  def create_branch(new_name, branch_name)
    ::Branches::CreateService.new(project, current_user).execute(new_name, branch_name)
  end

  def create_file(branch_name, file_name, content)
    Files::CreateService.new(
      project,
      current_user,
      start_branch: branch_name,
      branch_name: branch_name,
      commit_message: "Create file",
      file_path: file_name,
      file_content: content
    ).execute
    project.commit(branch_name)
  end

  def update_file(branch_name, file_name, content)
    Files::UpdateService.new(
      project,
      current_user,
      start_branch: branch_name,
      branch_name: branch_name,
      commit_message: "Update file",
      file_path: file_name,
      file_content: content
    ).execute
    project.commit(branch_name)
  end

  def delete_file(branch_name, file_name)
    Files::DeleteService.new(
      project,
      current_user,
      start_branch: branch_name,
      branch_name: branch_name,
      commit_message: "Delete file",
      file_path: file_name
    ).execute
    project.commit(branch_name)
  end
end
