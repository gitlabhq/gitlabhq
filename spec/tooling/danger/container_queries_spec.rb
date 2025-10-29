# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/container_queries'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ContainerQueries, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  include_context "with dangerfile"

  subject(:container_queries) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:modified_files) { ['app/services/llm/ai_service.rb'] }

  before do
    stub_const('Diff', Struct.new(:patch))
    stub_const('Git', Struct.new(:modified_files, :file_content) do
      def diff_for_file(_file)
        file_content ? Diff.new(file_content) : nil
      end
    end)

    allow(fake_helper).to receive_messages(all_changed_files: modified_files,
      git: Git.new(modified_files, file_content))
  end

  describe '#check' do
    subject(:check) { container_queries.check }

    where(:modified_file) do
      [
        'vue_file.vue',
        'js_file.js',
        'haml_template.haml',
        'ruby_file.rb',
        'erb_template.erb'
      ]
    end

    with_them do
      let(:modified_files) { [modified_file] }

      context 'when there are unexpected container queries' do
        let(:file_content) { '@sm:gl-hidden' }

        before do
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(Tooling::Danger::ContainerQueries::EXPANDED_PATH).and_return(<<~TXT)
          # Comments and empty lines are ignored

          #{modified_files}
          TXT
        end

        it 'warns' do
          expect(container_queries).to receive(:warn).with(Tooling::Danger::ContainerQueries::UNEXPECTED_CQS_MESSAGE)
          expect(container_queries).to receive(:markdown).with(
            a_string_including(modified_files.first)
          )
          check
        end
      end

      context 'when there are unexpected media queries' do
        let(:file_content) { 'sm:gl-hidden' }

        it 'warns' do
          expect(container_queries).to receive(:warn).with(Tooling::Danger::ContainerQueries::UNEXPECTED_MQS_MESSAGE)
          expect(container_queries).to receive(:markdown).with(
            a_string_including(modified_files.first)
          )
          check
        end
      end

      context 'when there are no unexpected queries' do
        let(:file_content) { 'foobar' }

        it 'does not warn' do
          expect(container_queries).not_to receive(:warn)

          check
        end
      end

      context 'when there are renames' do
        let(:file_content) { nil }

        it 'does not crash' do
          expect { check }.not_to raise_error
        end
      end
    end
  end
end
