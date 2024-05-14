# frozen_string_literal: true

RSpec.shared_examples 'checks if the doc is up-to-date' do
  subject(:check_docs_task) { described_class.new(docs_dir, docs_path, template_erb_path).run }

  shared_examples 'outputs an error' do
    before do
      stub_definitions
    end

    it 'raises an error' do
      expect { check_docs_task }.to raise_error(SystemExit).and output(/#{error_message}/).to_stdout
    end
  end

  context 'when custom_abilities.md is up to date' do
    it 'outputs success message after checking the documentation' do
      expect { check_docs_task }.to output(success_message).to_stdout
    end
  end

  context 'when custom_abilities.md is updated manually' do
    before do
      File.write(docs_path, "Manually adding this line at the end of the custom_abilities.md", mode: 'a+')
    end

    it 'raises an error' do
      expect { check_docs_task }.to raise_error(SystemExit).and output(/#{error_message}/).to_stdout
    end
  end

  context 'when an existing custom ability is removed' do
    let(:updated_definitions) { removed_definition }

    it_behaves_like 'outputs an error'
  end

  context 'when a new custom ability is added' do
    let(:updated_definitions) { added_definition }

    it_behaves_like 'outputs an error'
  end

  context 'when an existing audit event type is updated' do
    let(:updated_definitions) { updated_definition }

    it_behaves_like 'outputs an error'
  end
end
