# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tasks/ci/job_tokens_task'

RSpec.describe Tasks::Ci::JobTokensTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }
  let(:path) { Rails.root.join('tmp/tests/doc/ci/jobs') }
  let(:doc) { 'fine_grained_permissions.md' }
  let(:doc_path) { Rails.root.join(path, doc) }
  let(:routes) do
    [
      allowed_route_without_policies,
      allowed_route_with_invalid_policies,
      allowed_route_with_valid_policies,
      allowed_route_with_skipped_policies,
      not_allowed_route
    ]
  end

  before do
    allow(task).to receive_messages(routes: routes, doc_path: doc_path)
  end

  describe '#check_policies_completeness' do
    subject(:check_policies_completeness) { task.check_policies_completeness }

    context 'when no allowed routes without policies are found' do
      let(:routes) { [allowed_route_with_valid_policies] }

      it 'outputs a success message' do
        expect { check_policies_completeness }
          .to output("All allowed endpoints for CI/CD job tokens have policies defined.\n")
          .to_stdout
      end
    end

    context 'when allowed routes without policies are found' do
      let(:error_message) do
        <<~OUTPUT
          ##########
          #
          # The following endpoints allowed for CI/CD job tokens should define job token policies:
          #
          | Path | Description |
          | ---- | ----------- |
          | `GET path/to/allowed_route_without_policies` | route description |
          #
          ##########
        OUTPUT
      end

      it 'raises an error and outputs a routes table' do
        expect { check_policies_completeness }.to raise_error(SystemExit).and output(error_message).to_stdout
      end
    end
  end

  describe '#check_policies_correctness' do
    subject(:check_policies_correctness) { task.check_policies_correctness }

    context 'when no routes with invalid policies are found' do
      let(:routes) { [allowed_route_with_valid_policies] }

      it 'outputs a success message' do
        expect { check_policies_correctness }
          .to output("All defined CI/CD job token policies are valid.\n")
          .to_stdout
      end
    end

    context 'when routes with invalid policies are found' do
      let(:error_message) do
        <<~OUTPUT
          ##########
          #
          # The following endpoints have invalid CI/CD job token policies:
          #
          | Policies | Path | Description |
          | -------- | ---- | ----------- |
          | invalid_policy | `GET path/to/allowed_route_with_invalid_policies` | route description |
          #
          ##########
        OUTPUT
      end

      it 'raises an error and outputs a routes table' do
        expect { check_policies_correctness }.to raise_error(SystemExit).and output(error_message).to_stdout
      end
    end
  end

  describe '#check_docs' do
    subject(:check_docs) { task.check_docs }

    before do
      FileUtils.mkdir_p(path)
      task.compile_docs
    end

    context 'when the docs are up to date' do
      it 'outputs a success message' do
        expect { check_docs }
          .to output("CI/CD job token allowed endpoints documentation is up to date.\n")
          .to_stdout
      end
    end

    context 'when the doc is updated manually' do
      before do
        File.write(doc_path, 'Manually adding this line at the end of the the doc', mode: 'a+')
      end

      let(:error_message) do
        <<~OUTPUT
          ##########
          #
          # CI/CD job token allowed endpoints documentation is outdated! Please update it by running `bundle exec rake ci:job_tokens:compile_docs`.
          #
          ##########
        OUTPUT
      end

      it 'raises an error' do
        expect { check_docs }.to raise_error(SystemExit).and output(error_message).to_stdout
      end
    end

    context 'when the doc is not up to date' do
      before do
        allow(task).to receive(:routes).and_return([])
      end

      let(:error_message) do
        <<~OUTPUT
          ##########
          #
          # CI/CD job token allowed endpoints documentation is outdated! Please update it by running `bundle exec rake ci:job_tokens:compile_docs`.
          #
          ##########
        OUTPUT
      end

      it 'raises an error' do
        expect { check_docs }.to raise_error(SystemExit).and output(error_message).to_stdout
      end
    end
  end

  describe '#compile_docs' do
    subject(:compile_docs) { task.compile_docs }

    before do
      FileUtils.mkdir_p(path)
    end

    it 'outputs a success message' do
      expect { compile_docs }
        .to output("CI/CD job token allowed endpoints documentation compiled.\n")
        .to_stdout
    end

    it 'creates fine_grained_permissions.md', :aggregate_failures do
      FileUtils.rm_f(doc_path)
      expect { File.read(doc_path) }.to raise_error(Errno::ENOENT)
      expect(task).to receive(:allowed_endpoints)

      compile_docs

      expect(File.read(doc_path)).to match(/This documentation is auto generated by a Rake task/)
    end
  end

  describe '#allowed_endpoints' do
    let(:table) do
      <<~TABLE.chomp
        | Permissions | Permission Names | Path | Description |
        | ----------- | ---------------- | ---- | ----------- |
        | None |  | `GET path/to/allowed_route_with_skipped_policies` | route description |
        | None |  | `GET path/to/allowed_route_without_policies` | route description |
        | Packages: Read | `READ_PACKAGES` | `GET path/to/allowed_route_with_valid_policies` | route description |
        | invalid_policy | `INVALID_POLICY` | `GET path/to/allowed_route_with_invalid_policies` | route description |
      TABLE
    end

    it 'returns a sorted table for the docs that includes allowed routes only' do
      expect(task.allowed_endpoints).to eq(table)
    end
  end

  def allowed_route_without_policies
    instance_double(Grape::Router::Route,
      settings: {
        authentication: { job_token_allowed: true }
      },
      request_method: 'GET',
      description: 'route description',
      origin: 'path/to/allowed_route_without_policies'
    )
  end

  def allowed_route_with_invalid_policies
    instance_double(Grape::Router::Route,
      settings: {
        authentication: { job_token_allowed: true },
        authorization: { job_token_policies: :invalid_policy }
      },
      request_method: 'GET',
      description: 'route description',
      origin: 'path/to/allowed_route_with_invalid_policies'
    )
  end

  def allowed_route_with_valid_policies
    instance_double(Grape::Router::Route,
      settings: {
        authentication: { job_token_allowed: true },
        authorization: { job_token_policies: :read_packages }
      },
      request_method: 'GET',
      description: 'route description',
      origin: 'path/to/allowed_route_with_valid_policies'
    )
  end

  def allowed_route_with_skipped_policies
    instance_double(Grape::Router::Route,
      settings: {
        authentication: { job_token_allowed: true },
        authorization: { skip_job_token_policies: true }
      },
      request_method: 'GET',
      description: 'route description',
      origin: 'path/to/allowed_route_with_skipped_policies'
    )
  end

  def not_allowed_route
    instance_double(Grape::Router::Route,
      settings: {
        authentication: { job_token_allowed: false },
        authorization: { job_token_policies: :read_packages }
      },
      request_method: 'GET',
      description: 'route description',
      origin: 'path/to/route'
    )
  end
end
