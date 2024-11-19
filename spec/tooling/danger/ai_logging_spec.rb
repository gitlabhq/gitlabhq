# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/ai_logging'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::AiLogging, feature_category: :service_ping do
  include_context "with dangerfile"

  subject(:ai_logging) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:modified_files) { ['app/services/llm/ai_service.rb'] }

  before do
    stub_const('Diff', Struct.new(:patch))
    stub_const('Git', Struct.new(:modified_files, :file_content) do
      def diff_for_file(_file)
        Diff.new(file_content)
      end
    end)

    allow(fake_helper).to receive(:git).and_return(
      Git.new(modified_files, file_content)
    )
    allow(fake_helper).to receive(:stable_branch?).and_return(false)
    allow(fake_helper).to receive(:markdown_list).and_return("app/services/llm/ai_service.rb")
  end

  describe '#check_ai_logging' do
    subject(:check_ai_logging) { ai_logging.check_ai_logging }

    context 'when there are no AI logging issues' do
      let(:modified_files) { ['app/models/user.rb'] }
      let(:file_content) { 'def some_method; end' }

      it 'does not warn' do
        expect(ai_logging).not_to receive(:warn)
        check_ai_logging
      end
    end

    context 'when there are no AI logging issues but we are using same method name' do
      let(:modified_files) { ['app/models/user.rb'] }
      let(:file_content) { 'log_error(message: "test")' }

      it 'does not warn' do
        expect(ai_logging).not_to receive(:warn)
        check_ai_logging
      end
    end

    context 'when there are AI logging issues' do
      let(:modified_files) { ['app/services/duo/ai_service.rb'] }
      let(:file_content) { 'log_info(message: "Some AI log")' }

      it 'warns about non-compliant AI logging' do
        expect(ai_logging).to receive(:warn).with(Tooling::Danger::AiLogging::AI_LOGGING_WARNING)
        expect(ai_logging).to receive(:markdown).with(
          a_string_including(Tooling::Danger::AiLogging::AI_LOGGING_FILES_MESSAGE)
        )
        check_ai_logging
      end

      context 'when file content is multi-lined' do
        let(:file_content) do
          <<~TEXT
            log_info(
              message: "Some AI log"
            )
          TEXT
        end

        it 'warns about non-compliant AI logging' do
          expect(ai_logging).to receive(:warn).with(Tooling::Danger::AiLogging::AI_LOGGING_WARNING)
          expect(ai_logging).to receive(:markdown).with(
            a_string_including(Tooling::Danger::AiLogging::AI_LOGGING_FILES_MESSAGE)
          )
          check_ai_logging
        end
      end

      context 'when there is appropriate AI logging with log_conditional_info' do
        let(:modified_files) { ['app/services/llm/ai_service.rb'] }
        let(:file_content) { 'log_conditional_info(test_user, message: "Some AI log with log_conditional_info")' }

        it 'warns about non-compliant AI logging' do
          expect(ai_logging).not_to receive(:warn)

          check_ai_logging
        end
      end
    end
  end
end
