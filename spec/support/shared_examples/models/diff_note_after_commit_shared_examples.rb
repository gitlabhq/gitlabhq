# frozen_string_literal: true

RSpec.shared_examples 'a valid diff note with after commit callback' do
  context 'when diff file is fetched from repository' do
    before do
      allow_any_instance_of(::Gitlab::Diff::Position).to receive(:diff_file).with(project.repository).and_return(diff_file_from_repository)
    end

    context 'when diff_line is not found' do
      it 'raises an error' do
        allow(diff_file_from_repository).to receive(:line_for_position).with(position).and_return(nil)

        expect { subject.save! }.to raise_error(
          ::DiffNote::NoteDiffFileCreationError,
          "Failed to find diff line for: #{diff_file_from_repository.file_path}, "\
          "old_line: #{position.old_line}"\
          ", new_line: #{position.new_line}"
        )
      end
    end

    context 'when diff_line is found' do
      before do
        allow(diff_file_from_repository).to receive(:line_for_position).with(position).and_return(diff_line)
      end

      it 'fallback to fetch file from repository' do
        expect_any_instance_of(::Gitlab::Diff::Position).to receive(:diff_file).with(project.repository)

        subject.save!
      end

      it 'creates a diff note file' do
        subject.save!

        expect(subject.reload.note_diff_file).to be_present
      end
    end
  end

  context 'when diff file is not found in repository' do
    it 'raises an error' do
      allow_any_instance_of(::Gitlab::Diff::Position).to receive(:diff_file).with(project.repository).and_return(nil)

      expect { subject.save! }.to raise_error(::DiffNote::NoteDiffFileCreationError, 'Failed to find diff file')
    end
  end
end
