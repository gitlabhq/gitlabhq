# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FileHook do
  let(:file_hook) { Rails.root.join('file_hooks', 'test.rb') }
  let(:tmp_file) { Tempfile.new('file_hook-dump') }

  let(:file_hook_source) do
    <<~EOS
      #!/usr/bin/env ruby
      x = $stdin.read
      File.write('#{tmp_file.path}', x)
    EOS
  end

  context 'with file_hooks present' do
    before do
      File.write(file_hook, file_hook_source)
    end

    after do
      FileUtils.rm(file_hook)
    end

    describe '.any?' do
      it 'returns true' do
        expect(described_class.any?).to be true
      end
    end

    describe '.files?' do
      it 'returns a list of file_hooks' do
        expect(described_class.files).to match_array([file_hook.to_s])
      end
    end
  end

  context 'without any file_hooks' do
    describe '.any?' do
      it 'returns false' do
        expect(described_class.any?).to be false
      end
    end

    describe '.files' do
      it 'returns an empty list' do
        expect(described_class.files).to be_empty
      end
    end
  end

  describe '.execute' do
    let(:data) { Gitlab::DataBuilder::Push::SAMPLE_DATA }
    let(:result) { described_class.execute(file_hook.to_s, data) }
    let(:success) { result.first }
    let(:message) { result.last }

    before do
      File.write(file_hook, file_hook_source)
    end

    after do
      FileUtils.rm(file_hook)
    end

    context 'successful execution' do
      before do
        File.chmod(0o777, file_hook)
      end

      after do
        tmp_file.close!
      end

      it { expect(success).to be true }
      it { expect(message).to be_empty }

      it 'ensures file_hook received data via stdin' do
        result

        expect(File.read(tmp_file.path)).to eq(data.to_json)
      end
    end

    context 'non-executable' do
      it { expect(success).to be false }
      it { expect(message).to include('Permission denied') }
    end

    context 'non-zero exit' do
      let(:file_hook_source) do
        <<~EOS
          #!/usr/bin/env ruby
          exit 1
        EOS
      end

      before do
        File.chmod(0o777, file_hook)
      end

      it { expect(success).to be false }
      it { expect(message).to be_empty }
    end
  end
end
