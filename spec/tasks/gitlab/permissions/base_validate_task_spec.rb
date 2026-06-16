# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::BaseValidateTask, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let(:todo_file) { Pathname.new('/tmp/test_authorization_todo.txt') }

  let(:concrete_class) do
    todo = todo_file
    Class.new(described_class) do
      const_set(:TODO_FILE, todo)

      def current_todo_entries
        Set['entry_b', 'entry_a']
      end

      def todo_file_label
        'Test'
      end
    end
  end

  let(:task) { concrete_class.new }

  describe 'interface methods' do
    let(:test_class) { Class.new(described_class) }

    context 'when not implemented' do
      where(:method) do
        [
          :error_messages,
          :format_all_errors,
          :json_schema_file,
          :current_todo_entries,
          :todo_file_label
        ]
      end

      with_them do
        it 'raises NotImplementedError' do
          expect { test_class.new.send(method) }.to raise_error(NotImplementedError)
        end
      end
    end
  end

  describe '#extract_todo_header' do
    subject(:header) { task.send(:extract_todo_header) }

    context 'when the TODO file exists' do
      before do
        allow(todo_file).to receive_messages(exist?: true,
          readlines: ["# comment one\n", "# comment two\n", "entry_a\n"])
      end

      it 'returns only the comment lines joined as a string' do
        expect(header).to eq("# comment one\n# comment two\n")
      end
    end

    context 'when the TODO file does not exist' do
      before do
        allow(todo_file).to receive(:exist?).and_return(false)
      end

      it 'returns an empty string' do
        expect(header).to eq('')
      end
    end
  end

  describe '#sync_todo' do
    context 'when file entries match current entries (no stale entries)' do
      before do
        allow(todo_file).to receive_messages(exist?: true, readlines: %W[entry_a\n entry_b\n])
      end

      it 'returns without output' do
        expect { task.sync_todo }.not_to output.to_stdout
      end
    end

    context 'when there are stale entries' do
      before do
        allow(todo_file).to receive_messages(exist?: true, readlines: %W[entry_a\n entry_b\n entry_stale\n])
        allow(todo_file).to receive(:write)
      end

      it 'auto-updates the file and aborts with a commit reminder' do
        expect { task.sync_todo }
          .to raise_error(SystemExit)
          .and output(/had stale entries and has been updated.*Please commit/m).to_stdout
        expect(todo_file).to have_received(:write)
      end
    end
  end

  describe '#run' do
    before do
      allow(todo_file).to receive_messages(exist?: true, readlines: %W[entry_a\n entry_b\n])
      allow(task).to receive(:validate!)
      allow(task).to receive(:print_success_message)
    end

    it 'calls sync_todo when TODO_FILE is defined on the subclass' do
      expect(task).to receive(:sync_todo)
      task.run
    end

    context 'when TODO_FILE is not defined on the subclass' do
      let(:task) { Class.new(described_class).new }

      it 'does not call sync_todo' do
        expect(task).not_to receive(:sync_todo)
        task.run
      end
    end
  end

  describe '#update_todo' do
    before do
      allow(todo_file).to receive_messages(exist?: true, readlines: ["# preserved header\n"])
      allow(todo_file).to receive(:write)
    end

    it 'writes sorted entries prefixed by the preserved header to TODO_FILE' do
      task.update_todo

      expect(todo_file).to have_received(:write).with("# preserved header\nentry_a\nentry_b\n")
    end

    it 'prints a success message' do
      expect { task.update_todo }.to output(/updated/).to_stdout
    end
  end
end
