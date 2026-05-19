# frozen_string_literal: true

require 'fast_spec_helper'
require 'coverage'
require 'stringio'

require_relative '../support/per_test_coverage_formatter'

RSpec.describe Support::PerTestCoverageFormatter, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- support_specs is the conventional location for specs testing spec/support files
  let(:project_dir) { '/builds/gitlab-org/gitlab' }
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }
  let(:ndjson_file) { StringIO.new }

  let(:example_stub) { Struct.new(:id, keyword_init: true) }
  let(:example_notification_stub) { Struct.new(:example, keyword_init: true) }

  def notification_for(id)
    example_notification_stub.new(example: example_stub.new(id: id))
  end

  before do
    stub_const("#{described_class}::PROJECT_DIR_PREFIX_RE", %r{\A#{Regexp.escape(project_dir)}/})
    stub_env('CI_JOB_NAME_SLUG', 'rspec-unit-pg17-1-24')
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:open).and_return(ndjson_file)
  end

  describe '#example_finished' do
    it 'writes one NDJSON line with the example id and per-file line hits' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/models/user.rb" => { lines: [1, nil, 2, 0], branches: {} }
      )

      formatter.example_finished(notification_for('./spec/models/user_spec.rb[1:1]'))

      expect(ndjson_file.string).to eq(
        "#{Gitlab::Json.generate(id: './spec/models/user_spec.rb[1:1]',
          files: { 'app/models/user.rb' => [1, nil, 2, 0] })}\n"
      )
    end

    it 'writes one line per example when called multiple times' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))
      formatter.example_finished(notification_for('id2'))

      lines = ndjson_file.string.each_line.to_a
      expect(lines.length).to eq(2)
      expect(Gitlab::Json.safe_parse(lines[0])['id']).to eq('id1')
      expect(Gitlab::Json.safe_parse(lines[1])['id']).to eq('id2')
    end

    it 'filters out files outside CI_PROJECT_DIR' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} },
        '/usr/lib/ruby/3.3.0/json.rb' => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      record = Gitlab::Json.safe_parse(ndjson_file.string)
      expect(record['files'].keys).to contain_exactly('app/foo.rb')
    end

    it 'filters out files with no positive line hits' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/touched.rb" => { lines: [1], branches: {} },
        "#{project_dir}/app/untouched.rb" => { lines: [nil, 0, nil], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      record = Gitlab::Json.safe_parse(ndjson_file.string)
      expect(record['files'].keys).to contain_exactly('app/touched.rb')
    end

    it 'is a no-op when the delta has no qualifying files' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        '/usr/lib/ruby/3.3.0/json.rb' => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      expect(File).not_to have_received(:open)
      expect(ndjson_file.string).to be_empty
    end

    it 'accepts a bare line array (plain line mode)' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => [1, nil, 2]
      )

      formatter.example_finished(notification_for('id1'))

      record = Gitlab::Json.safe_parse(ndjson_file.string)
      expect(record['files']).to eq('app/foo.rb' => [1, nil, 2])
    end

    it 'skips files whose value is neither a hash with :lines nor an array' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      expect(ndjson_file.string).to be_empty
    end

    it 'opens the output file once across multiple examples' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))
      formatter.example_finished(notification_for('id2'))

      expect(File).to have_received(:open).once
    end
  end

  describe 'output file path' do
    it 'lands under tmp/ with rspec prefix, the job slug, and a random hex' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      expect(File).to have_received(:open).with(
        match(%r{\Atmp/per-test-coverage-rspec-rspec-unit-pg17-1-24-[0-9a-f]{12}\.ndjson\z}),
        'w'
      )
    end

    it 'falls back to "local" when CI_JOB_NAME_SLUG is unset' do
      stub_env('CI_JOB_NAME_SLUG', nil)
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      expect(File).to have_received(:open).with(
        match(%r{\Atmp/per-test-coverage-rspec-local-[0-9a-f]{12}\.ndjson\z}),
        'w'
      )
    end

    it 'creates the parent directory before opening the file' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )

      formatter.example_finished(notification_for('id1'))

      expect(FileUtils).to have_received(:mkdir_p).with('tmp')
    end
  end

  describe '#stop' do
    it 'closes the output file when one was opened' do
      allow(Coverage).to receive(:result).with(stop: false, clear: true).and_return(
        "#{project_dir}/app/foo.rb" => { lines: [1], branches: {} }
      )
      formatter.example_finished(notification_for('id1'))

      expect { formatter.stop(double) }.to change { ndjson_file.closed? }.from(false).to(true)
    end

    it 'is a no-op when no file was opened' do
      expect { formatter.stop(double) }.not_to raise_error
      expect(File).not_to have_received(:open)
    end
  end
end
