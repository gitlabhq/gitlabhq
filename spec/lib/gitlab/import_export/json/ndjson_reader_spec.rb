# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Json::NdjsonReader, feature_category: :importers do
  include ImportExport::CommonUtil

  let(:fixture) { 'spec/fixtures/lib/gitlab/import_export/light/tree' }
  let(:root_tree) { Gitlab::Json.parse(File.read(File.join(fixture, 'project.json'))) }
  let(:ndjson_reader) { described_class.new(dir_path) }
  let(:importable_path) { 'project' }

  describe '#exist?' do
    subject { ndjson_reader.exist? }

    context 'given valid dir_path' do
      let(:dir_path) { fixture }

      it { is_expected.to be true }
    end

    context 'given invalid dir_path' do
      let(:dir_path) { 'invalid-dir-path' }

      it { is_expected.to be false }
    end
  end

  describe '#consume_attributes' do
    let(:dir_path) { fixture }

    subject { ndjson_reader.consume_attributes(importable_path) }

    it 'returns the whole root tree from parsed JSON' do
      expect(subject).to eq(root_tree)
    end

    context 'when project.json is symlink or hard link' do
      using RSpec::Parameterized::TableSyntax

      where(:link_method) { [:link, :symlink] }

      with_them do
        it 'raises an error' do
          Dir.mktmpdir do |tmpdir|
            FileUtils.touch(File.join(tmpdir, 'passwd'))
            FileUtils.send(link_method, File.join(tmpdir, 'passwd'), File.join(tmpdir, 'project.json'))

            ndjson_reader = described_class.new(tmpdir)

            expect { ndjson_reader.consume_attributes(importable_path) }
              .to raise_error(Gitlab::ImportExport::Error, 'Invalid file')
          end
        end
      end
    end
  end

  describe '#consume_relation' do
    let(:dir_path) { fixture }

    subject { ndjson_reader.consume_relation(importable_path, key) }

    context 'given any key' do
      let(:key) { 'any-key' }

      it 'returns an Enumerator' do
        expect(subject).to be_an_instance_of(Enumerator)
      end
    end

    context 'key has been consumed' do
      let(:key) { 'issues' }

      before do
        ndjson_reader.consume_relation(importable_path, key).first
      end

      it 'yields nothing to the Enumerator' do
        expect(subject.to_a).to eq([])
      end

      context 'with mark_as_consumed: false' do
        subject { ndjson_reader.consume_relation(importable_path, key, mark_as_consumed: false) }

        it 'yields every relation value to the Enumerator' do
          expect(subject.count).to eq(1)
        end
      end
    end

    context 'key has not been consumed' do
      context 'relation file does not exist' do
        let(:key) { 'non-exist-relation-file-name' }

        before do
          relation_file_path = File.join(dir_path, importable_path, "#{key}.ndjson")
          expect(File).to receive(:exist?).with(relation_file_path).and_return(false)
        end

        it 'yields nothing to the Enumerator' do
          expect(subject.to_a).to eq([])
        end
      end

      context 'when relation file is a symlink or hard link' do
        using RSpec::Parameterized::TableSyntax

        where(:link_method) { [:link, :symlink] }

        with_them do
          it 'yields nothing to the Enumerator' do
            Dir.mktmpdir do |tmpdir|
              Dir.mkdir(File.join(tmpdir, 'project'))
              File.write(File.join(tmpdir, 'passwd'), "{}\n{}")
              FileUtils.send(link_method, File.join(tmpdir, 'passwd'), File.join(tmpdir, 'project', 'issues.ndjson'))

              ndjson_reader = described_class.new(tmpdir)

              result = ndjson_reader.consume_relation(importable_path, 'issues')

              expect(result.to_a).to eq([])
            end
          end
        end
      end

      context 'relation file is empty' do
        let(:key) { 'empty' }

        it 'yields nothing to the Enumerator' do
          expect(subject.to_a).to eq([])
        end
      end

      context 'relation file contains multiple lines' do
        let(:key) { 'custom_attributes' }
        let(:attr_1) { Gitlab::Json.parse('{"id":201,"project_id":5,"created_at":"2016-06-14T15:01:51.315Z","updated_at":"2016-06-14T15:01:51.315Z","key":"color","value":"red"}') }
        let(:attr_2) { Gitlab::Json.parse('{"id":202,"project_id":5,"created_at":"2016-06-14T15:01:51.315Z","updated_at":"2016-06-14T15:01:51.315Z","key":"size","value":"small"}') }

        it 'yields every relation value to the Enumerator' do
          expect(subject.to_a).to eq([[attr_1, 0], [attr_2, 1]])
        end
      end
    end
  end
end
