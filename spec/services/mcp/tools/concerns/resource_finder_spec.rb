# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::ResourceFinder, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::ResourceFinder

      def test_find_project(project_id)
        find_project(project_id)
      end
    end
  end

  let(:service) { test_class.new }

  describe '#find_project' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project) { create(:project, :public, namespace: namespace) }

    context 'with valid project ID' do
      it 'finds the project by ID' do
        result = service.test_find_project(project.id.to_s)
        expect(result).to eq(project)
      end
    end

    context 'with valid project full path' do
      it 'finds the project by full path' do
        result = service.test_find_project(project.full_path)
        expect(result).to eq(project)
      end
    end

    context 'with invalid input' do
      it 'raises ArgumentError for non-string input' do
        expect { service.test_find_project(123) }
          .to raise_error(ArgumentError, "project_id must be a string")
      end

      it 'raises ArgumentError for nil input' do
        expect { service.test_find_project(nil) }
          .to raise_error(ArgumentError, "project_id must be a string")
      end
    end

    context 'with non-existent project' do
      it 'raises StandardError for invalid ID' do
        expect { service.test_find_project(non_existing_record_id.to_s) }
          .to raise_error(StandardError, "Project '#{non_existing_record_id}' not found or inaccessible")
      end

      it 'raises StandardError for invalid path' do
        expect { service.test_find_project('invalid/path') }
          .to raise_error(StandardError, "Project 'invalid/path' not found or inaccessible")
      end
    end

    context 'with hidden project' do
      let_it_be(:hidden_project) { create(:project, :hidden) }

      it 'does not find hidden projects' do
        expect { service.test_find_project(hidden_project.id.to_s) }
          .to raise_error(StandardError, "Project '#{hidden_project.id}' not found or inaccessible")
      end
    end

    context 'with project path containing special characters' do
      let_it_be(:special_project) { create(:project, path: 'test-project_123') }

      it 'finds project with special characters in path' do
        result = service.test_find_project(special_project.full_path)
        expect(result).to eq(special_project)
      end
    end
  end
end
