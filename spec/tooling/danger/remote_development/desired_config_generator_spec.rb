# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../../tooling/danger/remote_development/desired_config_generator'
require_relative '../../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RemoteDevelopment::DesiredConfigGenerator, feature_category: :tooling do
  subject(:remote_development) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:shared_context_file) { described_class::REMOTE_DEVELOPMENT_SHARED_CONTEXT }
  let(:devfile_parser_file) { described_class::DEVFILE_PARSER }
  let(:desired_config_generator_file) { described_class::DESIRED_CONFIG_GENERATOR }
  let(:comment) { "" }
  let(:changed_files) { [] }
  let(:file_diff) do
    [
      "+Any changes to the file is valid...."
    ]
  end

  let(:file_lines) { file_diff.map { |line| line.delete_prefix('+') } }

  include_context "with dangerfile"

  describe '#add_comment_if_shared_context_updated' do
    shared_examples "adds a comment to the shared context file" do
      it 'adds comment to the shared_context file' do
        expect(remote_development).to receive(:markdown).with("\n#{comment}",
          file: shared_context_file, line: 1)
        remote_development.add_comment_if_shared_context_updated
      end
    end

    shared_examples "does not a comment to the shared context file" do
      it 'does not add any comment to the shared_context file' do
        expect(remote_development).not_to receive(:markdown)
        remote_development.add_comment_if_shared_context_updated
      end
    end

    before do
      allow(remote_development).to receive(:project_helper).and_return(fake_project_helper)
      allow(remote_development.helper).to receive(:all_changed_files).and_return(changed_files)
      allow(remote_development.helper).to receive(:changed_lines).with(shared_context_file).and_return(file_diff)
      allow(remote_development.project_helper).to receive(:file_lines).and_return(file_lines)
    end

    context 'when no relevant files changes' do
      it_behaves_like 'does not a comment to the shared context file'
    end

    context 'when only the shared_context_file changes' do
      let(:changed_files) { [shared_context_file] }

      it_behaves_like 'does not a comment to the shared context file'
    end

    context 'when the shared_context and devfile parser files change' do
      let(:changed_files) do
        [
          shared_context_file,
          devfile_parser_file
        ]
      end

      let(:comment) do
        <<~TEXT.chop
          This merge request updated the [`shared_context`](#{shared_context_file}) file \
          as well as the [`devfile_parser`](#{devfile_parser_file}) file. Please consider \
          reviewing any changes made to the `shared_context` file is valid.
        TEXT
      end

      it_behaves_like 'adds a comment to the shared context file'
    end

    context 'when the shared_context and desired_config files change' do
      let(:changed_files) do
        [
          shared_context_file,
          desired_config_generator_file
        ]
      end

      let(:comment) do
        <<~TEXT.chop
          This merge request updated the [`shared_context`](#{shared_context_file}) file \
          and the [`desired_config_generator`](#{desired_config_generator_file}) file\
          . Please consider reviewing any changes made to the `shared_context` file is valid.
        TEXT
      end

      it_behaves_like 'adds a comment to the shared context file'
    end

    context 'when the shared_context,dev_file_parser and desired_config files change' do
      let(:changed_files) do
        [
          shared_context_file,
          devfile_parser_file,
          desired_config_generator_file
        ]
      end

      let(:comment) do
        <<~TEXT.chop
          This merge request updated the [`shared_context`](#{shared_context_file}) file \
          as well as the [`devfile_parser`](#{devfile_parser_file}) file \
          and the [`desired_config_generator`](#{desired_config_generator_file}) file\
          . Please consider reviewing any changes made to the `shared_context` file is valid.
        TEXT
      end

      it_behaves_like 'adds a comment to the shared context file'
    end
  end
end
