# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::BaseTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }

  let(:params) { {} }

  # Create a concrete test implementation since BaseTool is abstract
  let(:test_tool_class) do
    Class.new(described_class) do
      register_version '1.0.0', {
        operation_name: 'testOperation',
        graphql_operation: 'mutation { test }'
      }

      def build_variables
        { input: {} }
      end

      # Expose protected methods for testing
      def test_resolve_parent
        resolve_parent
      end

      def test_resolve_work_item_id
        resolve_work_item_id
      end

      def test_validate_no_quick_actions!(text, field_name: 'text')
        validate_no_quick_actions!(text, field_name: field_name)
      end
    end
  end

  let(:tool) { test_tool_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe 'inheritance and includes' do
    it 'inherits from GraphqlTool' do
      expect(described_class.superclass).to eq(Mcp::Tools::GraphqlTool)
    end

    it 'includes Constants concern' do
      expect(described_class.included_modules).to include(Mcp::Tools::Concerns::Constants)
    end

    it 'includes ResourceFinder concern' do
      expect(described_class.included_modules).to include(Mcp::Tools::Concerns::ResourceFinder)
    end

    it 'includes UrlParser concern' do
      expect(described_class.included_modules).to include(Mcp::Tools::Concerns::UrlParser)
    end
  end

  describe '#resolve_parent' do
    context 'when URL is provided' do
      let(:params) { { url: "https://gitlab.com/#{project.full_path}" } }

      it 'resolves parent from URL' do
        result = tool.test_resolve_parent

        expect(result[:type]).to eq(:project)
        expect(result[:full_path]).to eq(project.full_path)
        expect(result[:record]).to eq(project)
      end

      it 'caches the result' do
        first_call = tool.test_resolve_parent
        second_call = tool.test_resolve_parent

        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end

    context 'when project_id is provided' do
      let(:params) { { project_id: project.id.to_s } }

      it 'resolves parent from project_id' do
        result = tool.test_resolve_parent

        expect(result[:type]).to eq(:project)
        expect(result[:full_path]).to eq(project.full_path)
        expect(result[:record]).to eq(project)
      end
    end

    context 'when group_id is provided' do
      let(:params) { { group_id: group.id.to_s } }

      it 'resolves parent from group_id' do
        result = tool.test_resolve_parent

        expect(result[:type]).to eq(:group)
        expect(result[:full_path]).to eq(group.full_path)
        expect(result[:record]).to eq(group)
      end
    end

    context 'when neither URL nor IDs are provided' do
      let(:params) { {} }

      it 'raises ArgumentError' do
        expect { tool.test_resolve_parent }
          .to raise_error(ArgumentError, 'Must provide either project_id or group_id')
      end
    end

    context 'when parent is not found' do
      let(:params) { { project_id: 'nonexistent/project', work_item_iid: 1 } }

      it 'raises StandardError from ResourceFinder' do
        expect { tool.test_resolve_parent }
          .to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when user lacks permission' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:params) { { project_id: private_project.id.to_s, work_item_iid: 1 } }

      it 'raises ArgumentError from authorization check' do
        expect { tool.test_resolve_parent }
          .to raise_error(ArgumentError, /Access denied/)
      end
    end

    context 'with invalid URL format' do
      let(:params) { { url: 'invalid-url' } }

      it 'raises ArgumentError from UrlParser' do
        expect { tool.test_resolve_parent }
          .to raise_error(ArgumentError, /Invalid URL format/)
      end
    end
  end

  describe '#resolve_work_item_id' do
    context 'when URL is provided' do
      let(:params) { { url: "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}" } }

      it 'resolves work item from URL and returns global ID' do
        result = tool.test_resolve_work_item_id

        expect(result).to eq(work_item.to_global_id.to_s)
      end

      it 'caches the result' do
        first_call = tool.test_resolve_work_item_id
        second_call = tool.test_resolve_work_item_id

        expect(first_call).to eq(second_call)
      end
    end

    context 'when project_id and work_item_iid are provided' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'resolves work item from params and returns global ID' do
        result = tool.test_resolve_work_item_id

        expect(result).to eq(work_item.to_global_id.to_s)
      end
    end

    context 'when work_item_iid is missing' do
      let(:params) { { project_id: project.id.to_s } }

      it 'raises ArgumentError' do
        expect { tool.test_resolve_work_item_id }
          .to raise_error(ArgumentError, 'Must provide work_item_iid')
      end
    end

    context 'when work item does not exist' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: 99999 } }

      it 'raises ArgumentError' do
        expect { tool.test_resolve_work_item_id }
          .to raise_error(ArgumentError, 'Work item #99999 not found')
      end
    end
  end

  describe '#validate_no_quick_actions!' do
    context 'when text contains no quick actions' do
      it 'does not raise error for regular text' do
        expect { tool.test_validate_no_quick_actions!('This is a regular comment') }
          .not_to raise_error
      end

      it 'does not raise error for text with slash in the middle' do
        expect { tool.test_validate_no_quick_actions!('This is a comment with /slash in middle') }
          .not_to raise_error
      end

      it 'does not raise error for nil text' do
        expect { tool.test_validate_no_quick_actions!(nil) }
          .not_to raise_error
      end

      it 'does not raise error for empty text' do
        expect { tool.test_validate_no_quick_actions!('') }
          .not_to raise_error
      end
    end

    context 'when text contains quick actions' do
      it 'raises ArgumentError for quick action at start' do
        expect { tool.test_validate_no_quick_actions!('/merge') }
          .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in text')
      end

      it 'raises ArgumentError for quick action with leading whitespace' do
        expect { tool.test_validate_no_quick_actions!('  /approve') }
          .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in text')
      end

      it 'raises ArgumentError for quick action in multiline text' do
        text = "Some description\n/assign @user\nMore text"
        expect { tool.test_validate_no_quick_actions!(text) }
          .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in text')
      end

      it 'uses custom field name in error message' do
        expect { tool.test_validate_no_quick_actions!('/close', field_name: 'description') }
          .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in description')
      end
    end
  end

  describe 'private methods' do
    describe '#resolve_parent_from_id' do
      context 'with project_id' do
        let(:params) { { project_id: project.full_path } }

        it 'resolves project and returns parent info' do
          result = tool.send(:resolve_parent_from_id)

          expect(result[:type]).to eq(:project)
          expect(result[:full_path]).to eq(project.full_path)
          expect(result[:record]).to eq(project)
        end
      end

      context 'with group_id' do
        let(:params) { { group_id: group.full_path } }

        it 'resolves group and returns parent info' do
          result = tool.send(:resolve_parent_from_id)

          expect(result[:type]).to eq(:group)
          expect(result[:full_path]).to eq(group.full_path)
          expect(result[:record]).to eq(group)
        end
      end

      context 'when neither project_id nor group_id is provided' do
        let(:params) { {} }

        it 'raises ArgumentError' do
          expect { tool.send(:resolve_parent_from_id) }
            .to raise_error(ArgumentError, 'Must provide either project_id or group_id')
        end
      end

      context 'when user lacks access' do
        let_it_be(:private_project) { create(:project, :private) }
        let(:params) { { project_id: private_project.id.to_s } }

        it 'raises ArgumentError' do
          expect { tool.send(:resolve_parent_from_id) }
            .to raise_error(ArgumentError, /Access denied to project/)
        end
      end
    end

    describe '#resolve_work_item_from_params' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'finds work item and returns global ID' do
        result = tool.send(:resolve_work_item_from_params)

        expect(result).to eq(work_item.to_global_id.to_s)
      end

      context 'when work_item_iid is missing' do
        let(:params) { { project_id: project.id.to_s } }

        it 'raises ArgumentError' do
          expect { tool.send(:resolve_work_item_from_params) }
            .to raise_error(ArgumentError, 'Must provide work_item_iid')
        end
      end

      context 'when work item does not exist' do
        let(:params) { { project_id: project.id.to_s, work_item_iid: 99999 } }

        it 'raises ArgumentError' do
          expect { tool.send(:resolve_work_item_from_params) }
            .to raise_error(ArgumentError, 'Work item #99999 not found')
        end
      end
    end
  end
end
