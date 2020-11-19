# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Output do
  let(:build) do
    create(:ci_build, pipeline: create(:ci_pipeline, source: :chat))
  end

  let(:output) { described_class.new(build) }
  let(:trace) { Gitlab::Ci::Trace.new(build) }

  before do
    trace.set("\e[0KRunning with gitlab-runner 13.4.0~beta.108.g2ed41114 (2ed41114)
\e[0;m\e[0K  on GDK local runner g_XWCUS4
\e[0;msection_start:1604068171:resolve_secrets\r\e[0K\e[0K\e[36;1mResolving secrets\e[0;m
\e[0;msection_end:1604068171:resolve_secrets\r\e[0Ksection_start:1604068171:prepare_executor\r\e[0K\e[0K\e[36;1mPreparing the \"docker\" executor\e[0;m
\e[0;m\e[0KUsing Docker executor with image ubuntu:20.04 ...
\e[0;m\e[0KUsing locally found image version due to if-not-present pull policy
\e[0;m\e[0KUsing docker image sha256:d70eaf7277eada08fca944de400e7e4dd97b1262c06ed2b1011500caa4decaf1 for ubuntu:20.04 with digest ubuntu@sha256:fff16eea1a8ae92867721d90c59a75652ea66d29c05294e6e2f898704bdb8cf1 ...
\e[0;msection_end:1604068172:prepare_executor\r\e[0Ksection_start:1604068172:prepare_script\r\e[0K\e[0K\e[36;1mPreparing environment\e[0;m
\e[0;mRunning on runner-gxwcus4-project-21-concurrent-0 via MacBook-Pro.local...
section_end:1604068173:prepare_script\r\e[0Ksection_start:1604068173:get_sources\r\e[0K\e[0K\e[36;1mGetting source from Git repository\e[0;m
\e[0;m\e[32;1mFetching changes with git depth set to 50...\e[0;m
Initialized empty Git repository in /builds/267388-group-1/playground/.git/
\e[32;1mCreated fresh repository.\e[0;m
\e[32;1mChecking out 6c8eb7f4 as master...\e[0;m

\e[32;1mSkipping Git submodules setup\e[0;m
section_end:1604068175:get_sources\r\e[0Ksection_start:1604068175:step_script\r\e[0K\e[0K\e[36;1mExecuting \"step_script\" stage of the job script\e[0;m
\e[0;m\e[32;1m$ echo \"success!\"\e[0;m
success!
section_end:1604068175:step_script\r\e[0Ksection_start:1604068175:chat_reply\r\033[0K
Chat Reply
section_end:1604068176:chat_reply\r\033[0K\e[32;1mJob succeeded
\e[0;m")
  end

  describe '#to_s' do
    it 'returns the chat reply as a String' do
      expect(output.to_s).to eq("Chat Reply")
    end

    context 'without the chat_reply trace section' do
      before do
        trace.set(trace.raw.gsub('chat_reply', 'not_found'))
      end

      it 'falls back to using the step_script trace section' do
        expect(output.to_s).to eq("\e[0;m\e[32;1m$ echo \"success!\"\e[0;m\nsuccess!")
      end

      context 'without the step_script trace section' do
        before do
          trace.set(trace.raw.gsub('step_script', 'build_script'))
        end

        it 'falls back to using the build_script trace section' do
          expect(output.to_s).to eq("\e[0;m\e[32;1m$ echo \"success!\"\e[0;m\nsuccess!")
        end

        context 'without the build_script trace section' do
          before do
            trace.set(trace.raw.gsub('build_script', 'not_found'))
          end

          it 'raises MissingBuildSectionError' do
            expect { output.to_s }
              .to raise_error(described_class::MissingBuildSectionError)
          end
        end
      end
    end
  end

  describe '#without_executed_command_line' do
    it 'returns the input without the first line' do
      expect(output.without_executed_command_line("hello\nworld"))
        .to eq('world')
    end

    it 'returns an empty String when the input is empty' do
      expect(output.without_executed_command_line('')).to eq('')
    end

    it 'returns an empty String when the input consits of a single newline' do
      expect(output.without_executed_command_line("\n")).to eq('')
    end
  end

  describe '#find_build_trace_section' do
    it 'returns nil when no section could be found' do
      expect(output.find_build_trace_section('foo')).to be_nil
    end

    it 'returns the trace section when it could be found' do
      section = { name: 'chat_reply', byte_start: 1, byte_end: 4 }

      allow(output)
        .to receive(:trace_sections)
        .and_return([section])

      expect(output.find_build_trace_section('chat_reply')).to eq(section)
    end
  end
end
