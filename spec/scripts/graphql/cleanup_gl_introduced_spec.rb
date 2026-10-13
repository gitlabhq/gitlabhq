# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require_relative '../../../scripts/graphql/cleanup_gl_introduced'

RSpec.describe CleanupGlIntroduced, feature_category: :tooling do
  subject(:cleanup) { described_class.new(root: root, dry_run: dry_run, output: output) }

  let(:root) { Dir.mktmpdir }
  let(:dry_run) { false }
  let(:output) { StringIO.new }
  let(:query_path) { File.join(root, 'app/assets/javascripts/foo/query.graphql') }

  before do
    File.write(File.join(root, 'VERSION'), "19.5.0-pre\n")
  end

  after do
    FileUtils.rm_rf(root)
  end

  def write_graphql(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe '#execute' do
    context 'with a directive older than the previous milestone' do
      before do
        write_graphql(query_path, <<~GRAPHQL)
          query foo {
            project {
              oldField @gl_introduced(version: "19.3.0")
              oldPreField @gl_introduced(version: "18.10.0-pre") {
                id
              }
              aliased: oldOwnLine(arg: 1)
                @gl_introduced(version: "18.7.0")
                @skip(if: $skip) {
                id
              }
            }
          }
        GRAPHQL
      end

      it 'removes the directives and keeps the surrounding query intact' do
        expect(cleanup.execute).to eq('app/assets/javascripts/foo/query.graphql' => 3)

        expect(File.read(query_path)).to eq(<<~GRAPHQL)
          query foo {
            project {
              oldField
              oldPreField {
                id
              }
              aliased: oldOwnLine(arg: 1)
                @skip(if: $skip) {
                id
              }
            }
          }
        GRAPHQL
        expect(output.string).to include('Removed 3 stale @gl_introduced directive(s)')
      end
    end

    context 'with a directive at the start of a line followed by another directive' do
      before do
        write_graphql(query_path, <<~GRAPHQL)
          query foo {
            field
              @gl_introduced(version: "19.0.0") @skip(if: $skip)
          }
        GRAPHQL
      end

      it 'keeps the indentation of the remaining directive' do
        cleanup.execute

        expect(File.read(query_path)).to eq(<<~GRAPHQL)
          query foo {
            field
              @skip(if: $skip)
          }
        GRAPHQL
      end
    end

    context 'with directives at or after the previous milestone' do
      let(:content) do
        <<~GRAPHQL
          query foo {
            previousField @gl_introduced(version: "19.4.0")
            previousPreField @gl_introduced(version: "19.4.0-pre")
            currentField @gl_introduced(version: "19.5.0")
            currentPreField @gl_introduced(version: "19.5.0-pre")
            futureField @gl_introduced(version: "19.6.0")
            nextMajorField @gl_introduced(version: "20.0.0")
            invalidField @gl_introduced(version: "foo")
          }
        GRAPHQL
      end

      before do
        write_graphql(query_path, content)
      end

      it 'keeps them and does not touch the file' do
        expect { expect(cleanup.execute).to be_empty }.not_to change { File.mtime(query_path) }

        expect(File.read(query_path)).to eq(content)
        expect(output.string).to include('No stale @gl_introduced directives found (older than milestone 19.4)')
      end
    end

    context 'with a mix of stale and current directives' do
      before do
        write_graphql(query_path, <<~GRAPHQL)
          query foo {
            oldField @gl_introduced(version: "19.3.0")
            previousField @gl_introduced(version: "19.4.0")
          }
        GRAPHQL
      end

      it 'removes only the stale directive' do
        cleanup.execute

        expect(File.read(query_path)).to eq(<<~GRAPHQL)
          query foo {
            oldField
            previousField @gl_introduced(version: "19.4.0")
          }
        GRAPHQL
      end
    end

    context 'with files in ee/app/assets and outside the frontend directories' do
      let(:ee_path) { File.join(root, 'ee/app/assets/javascripts/foo/query.graphql') }
      let(:backend_path) { File.join(root, 'spec/fixtures/query.graphql') }
      let(:content) { %(query foo { field @gl_introduced(version: "19.0.0") }\n) }

      before do
        write_graphql(ee_path, content)
        write_graphql(backend_path, content)
      end

      it 'only cleans the frontend files' do
        expect(cleanup.execute.keys).to eq(['ee/app/assets/javascripts/foo/query.graphql'])

        expect(File.read(ee_path)).to eq("query foo { field }\n")
        expect(File.read(backend_path)).to eq(content)
      end
    end

    context 'with dry_run' do
      let(:dry_run) { true }
      let(:content) { %(query foo { field @gl_introduced(version: "19.0.0") }\n) }

      before do
        write_graphql(query_path, content)
      end

      it 'reports the changes without modifying the file' do
        expect(cleanup.execute).to eq('app/assets/javascripts/foo/query.graphql' => 1)

        expect(File.read(query_path)).to eq(content)
        expect(output.string).to include(
          'Would remove 1 stale @gl_introduced directive(s) from app/assets/javascripts/foo/query.graphql'
        )
      end
    end
  end

  describe '#stale?' do
    where(:version, :stale) do
      [
        ['19.3.9', true],
        ['19.3.0-pre', true],
        ['18.11.0', true],
        ['19.4.0', false],
        ['19.4.9', false],
        ['19.4.0-pre', false],
        ['19.5.0', false],
        ['19.5.3', false],
        ['19.6.0', false],
        ['20.0.0', false],
        ['19.4', false],
        ['', false]
      ]
    end

    with_them do
      it { expect(cleanup.stale?(version)).to eq(stale) }
    end
  end

  describe '.previous_milestone' do
    where(:milestone, :previous) do
      [
        [[19, 5], [19, 4]],
        [[19, 1], [19, 0]],
        [[20, 0], [19, 11]]
      ]
    end

    with_them do
      it { expect(described_class.previous_milestone(milestone)).to eq(previous) }
    end
  end

  describe '#initialize' do
    it 'raises for an invalid VERSION' do
      expect { described_class.new(root: root, version: 'foo') }.to raise_error(ArgumentError, /Invalid version/)
    end
  end

  describe 'command line' do
    let(:script) { File.expand_path('../../../scripts/graphql/cleanup_gl_introduced.rb', __dir__) }

    it 'prints the current milestone with --version' do
      stdout, status = Open3.capture2('ruby', script, '--version')

      expect(status).to be_success
      expect(stdout).to eq("#{File.read(File.join(described_class::ROOT, 'VERSION'))[/\A\d+\.\d+/]}\n")
    end
  end
end
