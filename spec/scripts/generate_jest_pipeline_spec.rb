# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

require_relative '../../scripts/generate_jest_pipeline'

RSpec.describe GenerateJestPipeline, :silence_stdout, feature_category: :tooling do
  describe '#generate!' do
    let!(:jest_files) { Tempfile.new(['jest_files_path', '.txt']) }
    let(:pipeline_template) { Tempfile.new(['pipeline_template', '.yml.erb']) }
    let(:pipeline_template_content) do
      <<~YAML
        jest per-test-coverage:
        <% if parallelism > 1 %>
          parallel: <%= parallelism %>
        <% end %>
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

      it 'renders without a parallel: directive' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content).to include('jest per-test-coverage:')
        expect(content).not_to include('parallel:')
      end
    end

    context 'with a large queue (caps at MAX_PARALLEL_DEFAULT)' do
      before do
        # 6000 spec files / 500 per shard = 12 shards, capped at 11.
        files = Array.new(6_000) { |i| "spec/frontend/large_#{i}_spec.js" }
        jest_files.write(files.join("\n"))
        jest_files.rewind
      end

      it 'renders with parallel: capped at the default max' do
        generator.generate!

        content = File.read("#{pipeline_template.path}.yml")
        expect(content).to include("parallel: #{described_class::MAX_PARALLEL_DEFAULT}")
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
        expect(content).to include('parallel: 3')
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
  end
end
