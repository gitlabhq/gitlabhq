# frozen_string_literal: true

require 'spec_helper'

describe Backup::Database do
  let(:progress) { double('progress', print: nil, puts: nil) }

  describe '#dump' do
    subject { described_class.new(progress).dump }

    let(:pg_schema) { nil }
    let(:backup_config) { double('config', pg_schema: pg_schema, path: File.join(Rails.root, 'tmp')) }

    before do
      allow(Settings).to receive(:backup).and_return(backup_config)
      allow(Process).to receive(:waitpid)
    end

    it 'does not limit pg_dump to any specific schema' do
      expect(Process).to receive(:spawn) do |*cmd, _|
        expect(cmd.join(' ')).not_to include('-n')
      end

      subject
    end

    it 'includes option to drop objects before restoration' do
      expect(Process).to receive(:spawn) do |*cmd, _|
        expect(cmd.join(' ')).to include('--clean')
      end

      subject
    end

    context 'with pg_schema configured explicitly' do
      let(:pg_schema) { 'some_schema' }

      it 'calls pg_dump' do
        expect(Process).to receive(:spawn) do |*cmd, _|
          expect(cmd.join(' ')).to start_with('pg_dump')
        end

        subject
      end

      it 'limits the psql dump to the specified schema' do
        expect(Process).to receive(:spawn) do |*cmd, _|
          expect(cmd.join(' ')).to include("-n #{pg_schema}")
        end

        subject
      end

      context 'extra schemas' do
        Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
          it "includes the extra schema #{schema}" do
            expect(Process).to receive(:spawn) do |*cmd, _|
              expect(cmd.join(' ')).to include("-n #{schema}")
            end

            subject
          end
        end
      end
    end
  end
end
