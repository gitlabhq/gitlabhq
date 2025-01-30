# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::CreateProjectService, :aggregate_failures, feature_category: :importers do
  let(:fake_file_acquisition_strategy) do
    Class.new do
      attr_reader :errors

      def initialize(...)
        @errors = ActiveModel::Errors.new(self)
      end

      def valid?
        true
      end

      def project_params
        {}
      end
    end
  end

  let(:params) do
    {
      path: 'path',
      namespace: user.namespace,
      name: 'name'
    }
  end

  let_it_be(:user) { create(:user) }

  subject { described_class.new(user, params: params, file_acquisition_strategy: FakeStrategy) }

  before do
    stub_const('FakeStrategy', fake_file_acquisition_strategy)
    stub_application_setting(import_sources: ['gitlab_project'])
  end

  describe 'validation' do
    it { expect(subject).to be_valid }

    it 'validates presence of path' do
      params[:path] = nil

      invalid = described_class.new(user, params: params, file_acquisition_strategy: FakeStrategy)

      expect(invalid).not_to be_valid
      expect(invalid.errors.full_messages).to include("Path can't be blank")
    end

    it 'validates presence of name' do
      params[:namespace] = nil

      invalid = described_class.new(user, params: params, file_acquisition_strategy: FakeStrategy)

      expect(invalid).not_to be_valid
      expect(invalid.errors.full_messages).to include("Namespace can't be blank")
    end

    it 'is invalid if the strategy is invalid' do
      expect_next_instance_of(FakeStrategy) do |strategy|
        allow(strategy).to receive(:valid?).and_return(false)
        allow(strategy).to receive(:errors).and_wrap_original do |original|
          original.call.tap do |errors|
            errors.add(:base, "some error")
          end
        end
      end

      invalid = described_class.new(user, params: params, file_acquisition_strategy: FakeStrategy)

      expect(invalid).not_to be_valid
      expect(invalid.errors.full_messages).to include("some error")
      expect(invalid.errors.full_messages).to include("some error")
    end
  end

  describe '#execute' do
    it 'creates a project successfully' do
      response = nil
      expect { response = subject.execute }
        .to change(Project, :count).by(1)

      expect(response).to be_success
      expect(response.http_status).to eq(:ok)
      expect(response.payload).to be_instance_of(Project)
      expect(response.payload.name).to eq('name')
      expect(response.payload.path).to eq('path')
      expect(response.payload.namespace).to eq(user.namespace)

      project = Project.last
      expect(project.name).to eq('name')
      expect(project.path).to eq('path')
      expect(project.namespace_id).to eq(user.namespace.id)
      expect(project.import_type).to eq('gitlab_project')
    end

    context 'when the project creation raises an error' do
      it 'fails to create a project' do
        expect_next_instance_of(Projects::GitlabProjectsImportService) do |service|
          expect(service).to receive(:execute).and_raise(StandardError, "failed to create project")
        end

        response = nil
        expect { response = subject.execute }
          .to change(Project, :count).by(0)

        expect(response).to be_error
        expect(response.http_status).to eq(:bad_request)
        expect(response.message).to eq("failed to create project")
        expect(response.payload).to eq(other_errors: [])
      end
    end

    context 'when the validation fail' do
      it 'fails to create a project' do
        params.delete(:path)

        response = nil
        expect { response = subject.execute }
          .to change(Project, :count).by(0)

        expect(response).to be_error
        expect(response.http_status).to eq(:bad_request)
        expect(response.message).to eq("Path can't be blank")
        expect(response.payload).to eq(other_errors: [])
      end

      context 'when the project contains multiple errors' do
        it 'fails to create a project' do
          params.merge!(name: '_ an invalid name _', path: '_ an invalid path _')

          response = nil
          expect { response = subject.execute }
            .to change(Project, :count).by(0)

          expect(response).to be_error
          expect(response.http_status).to eq(:bad_request)
          expect(response.message).to eq(
            "Project namespace path can only include non-accented letters, digits, '_', '-' and '.'. It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'."
          )
          expect(response.payload).to eq(
            other_errors: [
              %(Project namespace path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'),
              %(Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'),
              %(Path can only include non-accented letters, digits, '_', '-' and '.'. It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'.)
            ])
        end
      end
    end

    context 'when the strategy adds project parameters' do
      before do
        expect_next_instance_of(FakeStrategy) do |strategy|
          expect(strategy).to receive(:project_params).and_return(name: 'the strategy name')
        end

        subject.valid?
      end

      it 'merges the strategy project parameters' do
        response = nil
        expect { response = subject.execute }
          .to change(Project, :count).by(1)

        expect(response).to be_success
        expect(response.http_status).to eq(:ok)
        expect(response.payload).to be_instance_of(Project)
        expect(response.payload.name).to eq('the strategy name')
        expect(response.payload.path).to eq('path')
        expect(response.payload.namespace).to eq(user.namespace)

        project = Project.last
        expect(project.name).to eq('the strategy name')
        expect(project.path).to eq('path')
        expect(project.namespace_id).to eq(user.namespace.id)
        expect(project.import_type).to eq('gitlab_project')
      end
    end
  end
end
