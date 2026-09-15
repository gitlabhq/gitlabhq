# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'yaml'

require_relative '../../scripts/generate_jest_pipeline'

RSpec.describe GenerateJestPipeline, :silence_stdout, feature_category: :tooling do
  describe 'FIXTURE_SHARD_COUNT' do
    it 'matches parallel: on rspec-all frontend_fixture, whose shards the template enumerates as needs' do
      # frontend.gitlab-ci.yml uses !reference tags. Whether that tag is
      # already registered with Psych depends on suite run order, so
      # register and permit it explicitly instead of relying on it.
      Psych.add_tag('!reference', Gitlab::Ci::Config::Yaml::Tags::Reference)
      frontend_ci_path = File.expand_path('../../.gitlab/ci/frontend.gitlab-ci.yml', __dir__)
      parallel = YAML.safe_load(
        File.read(frontend_ci_path),
        permitted_classes: [Gitlab::Ci::Config::Yaml::Tags::Reference],
        aliases: true
      ).dig('rspec-all frontend_fixture', 'parallel')

      expect(described_class::FIXTURE_SHARD_COUNT).to eq(parallel)
    end
  end

  describe '#generate!' do
    let!(:jest_files) { Tempfile.new(['jest_files_path', '.txt']) }
    let(:pipeline_template) { Tempfile.new(['pipeline_template', '.yml.erb']) }
    let(:pipeline_template_content) do
      <<~YAML
        jest per-test-coverage:
        <% if parallelism > 1 %>
          parallel: <%= parallelism %>
        <% end %>
        jest-with-fixtures per-test-coverage:
          parallel: <%= fixture_parallelism %>
      YAML
    end

    around do |example|
      pipeline_template.write(pipeline_template_content)
      pipeline_template.rewind
      example.run
    ensure
      jest_files.close
      jest_files.unlink
      pipeline_template.close
      pipeline_template.unlink
    end

    subject(:generator) do
      described_class.new(
        pipeline_template_path: pipeline_template.path,
        jest_files_path: jest_files.path
      )
    end

    context 'when the jest queue file is empty' do
      it 'falls back to skip.yml' do
        generator.generate!

        # File should match the skip.yml fixture, which contains a `no-op:` job.
        expect(File.read("#{pipeline_template.path}.yml")).to include('no-op:')
      end
    end

    context 'when the jest queue file does not exist' do
      subject(:generator) do
        described_class.new(
          pipeline_template_path: pipeline_template.path,
          jest_files_path: '/nonexistent/queue.txt'
        )
      end

      it 'treats it as empty and falls back to skip.yml' do
        generator.generate!

        expect(File.read("#{pipeline_template.path}.yml")).to include('no-op:')
      end
    end

    context 'with a small queue (single shard)' do
      before do
        jest_files.write(%w[spec/frontend/a_spec.js spec/frontend/b_spec.js].join("\n"))
        jest_files.rewind
      end

      it 'renders the main pass without parallel: and the fixture pass at 1' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content).to include('jest per-test-coverage:')
        expect(content.scan(/parallel: (\d+)/).flatten).to eq(%w[1])
      end
    end

    context 'with a large queue (caps at MAX_PARALLEL_DEFAULT)' do
      before do
        # 6000 spec files / 500 per shard = 12 shards, capped at 11.
        files = Array.new(6_000) { |i| "spec/frontend/large_#{i}_spec.js" }
        jest_files.write(files.join("\n"))
        jest_files.rewind
      end

      it 'renders with parallel: capped at the default max and the fixture pass at its own cap' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content.scan(/parallel: (\d+)/).flatten).to eq(
          [described_class::MAX_PARALLEL_DEFAULT.to_s, described_class::MAX_FIXTURE_PARALLEL.to_s]
        )
      end
    end

    context 'with a medium queue scaling linearly' do
      before do
        # 1500 / 500 = 3 shards.
        files = Array.new(1_500) { |i| "spec/frontend/mid_#{i}_spec.js" }
        jest_files.write(files.join("\n"))
        jest_files.rewind
      end

      it 'renders with parallel: matching the queue-size math' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content.scan(/parallel: (\d+)/).flatten).to eq(%w[3 2])
      end
    end

    context 'with a custom max_parallel override' do
      subject(:generator) do
        described_class.new(
          pipeline_template_path: pipeline_template.path,
          jest_files_path: jest_files.path,
          max_parallel: 4
        )
      end

      before do
        files = Array.new(3_000) { |i| "spec/frontend/cap_#{i}_spec.js" }
        jest_files.write(files.join("\n"))
        jest_files.rewind
      end

      it 'caps parallelism at the override' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content).to include('parallel: 4')
      end
    end

    context 'with a non-positive max_parallel value' do
      [0, -1].each do |bad_value|
        context "with max_parallel: #{bad_value}" do
          subject(:generator) do
            described_class.new(
              pipeline_template_path: pipeline_template.path,
              jest_files_path: jest_files.path,
              max_parallel: bad_value
            )
          end

          before do
            files = Array.new(6_000) { |i| "spec/frontend/fb_#{i}_spec.js" }
            jest_files.write(files.join("\n"))
            jest_files.rewind
          end

          it 'falls back to MAX_PARALLEL_DEFAULT' do
            generator.generate!

            content = File.read("#{pipeline_template.path}.yml")
            expect(content).to include("parallel: #{described_class::MAX_PARALLEL_DEFAULT}")
          end
        end
      end
    end

    context 'with the real child pipeline template' do
      let(:generated_pipeline) { Tempfile.new(['generated_pipeline', '.yml']) }

      subject(:generator) do
        described_class.new(
          pipeline_template_path: '.gitlab/ci/per_test_coverage/jest_child_pipeline_template.erb',
          jest_files_path: jest_files.path,
          generated_pipeline_path: generated_pipeline.path
        )
      end

      before do
        jest_files.write(%w[spec/frontend/a_spec.js spec/frontend/b_spec.js].join("\n"))
        jest_files.rewind
      end

      after do
        generated_pipeline.close
        generated_pipeline.unlink
      end

      it 'renders valid YAML with a non-fixture and a fixture capture pass' do
        generator.generate!

        yaml = YAML.safe_load(File.read(generated_pipeline.path))

        expect(yaml.keys).to include('jest per-test-coverage', 'jest-with-fixtures per-test-coverage')

        shard_count = described_class::FIXTURE_SHARD_COUNT
        expected_shard_needs = (1..shard_count).map { |i| "rspec-all frontend_fixture #{i}/#{shard_count}" }
        fixture_needs = yaml['jest-with-fixtures per-test-coverage']['needs'].map { |need| need['job'] }
        expect(fixture_needs).to include(*expected_shard_needs, 'rspec-all frontend_fixture clickhouse')
        expect(yaml['jest-with-fixtures per-test-coverage']['script'].join).to include('--fixtures')
        expect(yaml['jest per-test-coverage']['script'].join).not_to include('--fixtures')
      end
    end
  end
end
