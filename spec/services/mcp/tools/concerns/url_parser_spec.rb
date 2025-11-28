# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::UrlParser, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::Constants
      include Mcp::Tools::Concerns::ResourceFinder
      include Mcp::Tools::Concerns::UrlParser

      attr_accessor :current_user

      def initialize(user)
        @current_user = user
      end
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:group_work_item) { create(:work_item, :epic, namespace: group, iid: 123) }

  let(:service) { test_class.new(user) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe '#extract_path_from_url' do
    it 'extracts path from valid URL' do
      url = 'https://gitlab.com/namespace/project'
      expect(service.send(:extract_path_from_url, url)).to eq('namespace/project')
    end

    it 'removes leading slash from path' do
      url = 'https://gitlab.com/namespace/project/-/work_items/42'
      expect(service.send(:extract_path_from_url, url)).to eq('namespace/project/-/work_items/42')
    end

    it 'handles URLs with query parameters' do
      url = 'https://gitlab.com/namespace/project?param=value'
      expect(service.send(:extract_path_from_url, url)).to eq('namespace/project')
    end

    it 'handles URLs with fragments' do
      url = 'https://gitlab.com/namespace/project#section'
      expect(service.send(:extract_path_from_url, url)).to eq('namespace/project')
    end

    it 'raises ArgumentError for invalid URL' do
      expect { service.send(:extract_path_from_url, 'not a valid url') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end
  end

  describe '#valid_url?' do
    it 'returns true for HTTPS URL' do
      expect(service.send(:valid_url?, 'https://gitlab.com/namespace/project')).to be true
    end

    it 'returns true for HTTP URL' do
      expect(service.send(:valid_url?, 'http://gitlab.com/namespace/project')).to be true
    end

    it 'returns false for URL without scheme' do
      expect(service.send(:valid_url?, 'gitlab.com/namespace/project')).to be false
    end

    it 'returns false for invalid scheme' do
      expect(service.send(:valid_url?, 'ftp://gitlab.com/file')).to be false
    end

    it 'raises ArgumentError for malformed URL' do
      expect { service.send(:valid_url?, 'https://gitlab.com:invalid/path') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end
  end

  describe '#parse_parent_url' do
    context 'with project URLs' do
      it 'parses simple project URL' do
        url = 'https://gitlab.com/namespace/project'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :project, path: 'namespace/project' })
      end

      it 'parses nested project URL' do
        url = 'https://gitlab.com/parent/child/project'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :project, path: 'parent/child/project' })
      end

      it 'parses project URL with trailing segments' do
        url = 'https://gitlab.com/namespace/project/-/merge_requests'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :project, path: 'namespace/project' })
      end
    end

    context 'with group URLs' do
      it 'parses group URL with groups prefix' do
        url = 'https://gitlab.com/groups/namespace/group'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :group, path: 'namespace/group' })
      end

      it 'parses nested group URL' do
        url = 'https://gitlab.com/groups/parent/child/grandchild'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :group, path: 'parent/child/grandchild' })
      end

      it 'removes groups prefix from path' do
        url = 'https://gitlab.com/groups/namespace/group/-/work_items'
        result = service.send(:parse_parent_url, url)

        expect(result).to eq({ type: :group, path: 'namespace/group' })
      end
    end
  end

  describe '#parse_work_item_url' do
    context 'with valid project work item URLs' do
      it 'parses project work item URL' do
        url = 'https://gitlab.com/namespace/project/-/work_items/42'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :project,
          parent_path: 'namespace/project',
          work_item_iid: 42
        })
      end

      it 'parses nested project work item URL' do
        url = 'https://gitlab.com/parent/child/project/-/work_items/999'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :project,
          parent_path: 'parent/child/project',
          work_item_iid: 999
        })
      end
    end

    context 'with valid group work item URLs' do
      it 'parses group work item URL' do
        url = 'https://gitlab.com/groups/namespace/group/-/work_items/123'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :group,
          parent_path: 'namespace/group',
          work_item_iid: 123
        })
      end

      it 'parses nested group work item URL' do
        url = 'https://gitlab.com/groups/parent/child/-/work_items/456'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :group,
          parent_path: 'parent/child',
          work_item_iid: 456
        })
      end
    end

    context 'with invalid URLs' do
      it 'raises ArgumentError for missing work_items segment' do
        url = 'https://gitlab.com/namespace/project/-/issues/42'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end

      it 'raises ArgumentError for missing iid' do
        url = 'https://gitlab.com/namespace/project/-/work_items/'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end

      it 'raises ArgumentError for non-numeric iid' do
        url = 'https://gitlab.com/namespace/project/-/work_items/abc'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end

      it 'raises ArgumentError for malformed URL' do
        url = 'https://gitlab.com/namespace/project/work_items/42'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end
    end
  end

  describe '#resolve_parent_from_url' do
    context 'with project URLs' do
      it 'resolves project from URL' do
        url = "https://gitlab.com/#{project.full_path}"
        result = service.send(:resolve_parent_from_url, url)

        expect(result[:type]).to eq(:project)
        expect(result[:full_path]).to eq(project.full_path)
        expect(result[:record]).to eq(project)
      end

      it 'raises ArgumentError when project not found' do
        url = 'https://gitlab.com/nonexistent/project'

        allow(service).to receive(:find_parent_by_id_or_path).and_return(nil)

        expect { service.send(:resolve_parent_from_url, url) }
          .to raise_error(ArgumentError, /Project not found/)
      end
    end

    context 'with group URLs' do
      it 'resolves group from URL' do
        url = "https://gitlab.com/groups/#{group.full_path}"
        result = service.send(:resolve_parent_from_url, url)

        expect(result[:type]).to eq(:group)
        expect(result[:full_path]).to eq(group.full_path)
        expect(result[:record]).to eq(group)
      end

      it 'raises ArgumentError when group not found' do
        url = 'https://gitlab.com/groups/nonexistent/group'

        allow(service).to receive(:find_parent_by_id_or_path).and_return(nil)

        expect { service.send(:resolve_parent_from_url, url) }
          .to raise_error(ArgumentError, /Group not found/)
      end
    end

    context 'with access control' do
      let_it_be(:private_project) { create(:project, :private) }

      it 'raises ArgumentError when user lacks access to project' do
        url = "https://gitlab.com/#{private_project.full_path}"

        expect { service.send(:resolve_parent_from_url, url) }
          .to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end

  describe '#resolve_work_item_from_url' do
    context 'with valid project work item URL' do
      it 'resolves work item and returns global ID' do
        url = "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}"
        result = service.send(:resolve_work_item_from_url, url)

        expect(result).to eq(work_item.to_global_id.to_s)
      end
    end

    context 'with valid group work item URL' do
      it 'resolves work item and returns global ID' do
        url = "https://gitlab.com/groups/#{group.full_path}/-/work_items/#{group_work_item.iid}"

        allow(service).to receive(:find_work_item_in_parent).with(group, group_work_item.iid)
          .and_return(group_work_item)

        result = service.send(:resolve_work_item_from_url, url)

        expect(result).to eq(group_work_item.to_global_id.to_s)
      end
    end

    context 'with invalid parent' do
      it 'raises ArgumentError when parent not found' do
        url = 'https://gitlab.com/nonexistent/project/-/work_items/42'

        allow(service).to receive(:find_parent_by_id_or_path).and_return(nil)

        expect { service.send(:resolve_work_item_from_url, url) }
          .to raise_error(ArgumentError, /Project not found/)
      end
    end

    context 'with invalid work item' do
      it 'raises ArgumentError when work item not found' do
        url = "https://gitlab.com/#{project.full_path}/-/work_items/99999"

        expect { service.send(:resolve_work_item_from_url, url) }
          .to raise_error(ArgumentError, /Work item #99999 not found/)
      end
    end

    context 'with access control' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:private_work_item) { create(:work_item, :issue, project: private_project, iid: 1) }

      it 'raises ArgumentError when user lacks access to parent' do
        url = "https://gitlab.com/#{private_project.full_path}/-/work_items/#{private_work_item.iid}"

        expect { service.send(:resolve_work_item_from_url, url) }
          .to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end
end
