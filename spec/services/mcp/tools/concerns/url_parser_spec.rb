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

    it 'extracts path from an HTTP URL' do
      url = 'http://gitlab.com/namespace/project'
      expect(service.send(:extract_path_from_url, url)).to eq('namespace/project')
    end

    it 'raises ArgumentError for URL without scheme' do
      expect { service.send(:extract_path_from_url, 'gitlab.com/namespace/project') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end

    it 'raises ArgumentError for invalid scheme' do
      expect { service.send(:extract_path_from_url, 'ftp://gitlab.com/file') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end

    it 'raises ArgumentError for malformed URL' do
      expect { service.send(:extract_path_from_url, 'https://gitlab.com:invalid/path') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end

    context 'when the instance is served under a relative URL root' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
      end

      it 'strips the relative URL root from the path' do
        url = 'https://gitlab.example.com/gitlab/namespace/project/-/work_items/42'
        expect(service.send(:extract_path_from_url, url)).to eq('namespace/project/-/work_items/42')
      end

      it 'does not strip a path segment that merely matches the root name' do
        url = 'https://gitlab.example.com/gitlab-org/project'
        expect(service.send(:extract_path_from_url, url)).to eq('gitlab-org/project')
      end

      it 'strips the relative URL root from a group work item path' do
        url = 'https://gitlab.example.com/gitlab/groups/namespace/group/-/work_items/42'
        expect(service.send(:extract_path_from_url, url)).to eq('groups/namespace/group/-/work_items/42')
      end
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

      it 'parses project issue URL' do
        url = 'https://gitlab.com/namespace/project/-/issues/42'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :project,
          parent_path: 'namespace/project',
          work_item_iid: 42
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

      it 'parses group epic URL' do
        url = 'https://gitlab.com/groups/namespace/group/-/epics/123'
        result = service.send(:parse_work_item_url, url)

        expect(result).to eq({
          parent_type: :group,
          parent_path: 'namespace/group',
          work_item_iid: 123
        })
      end
    end

    context 'with invalid URLs' do
      it 'raises ArgumentError for an epic segment on a project URL' do
        url = 'https://gitlab.com/namespace/project/-/epics/42'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end

      it 'raises ArgumentError for an issue segment on a group URL' do
        url = 'https://gitlab.com/groups/namespace/group/-/issues/42'

        expect { service.send(:parse_work_item_url, url) }
          .to raise_error(ArgumentError, /Invalid work item URL format/)
      end

      it 'raises ArgumentError for a non-work-item resource segment' do
        url = 'https://gitlab.com/namespace/project/-/merge_requests/42'

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

  describe '#parse_blob_url' do
    context 'with valid file URLs' do
      it 'parses a blob URL' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/app/models/user.rb'
        result = service.send(:parse_blob_url, url)

        expect(result).to eq({
          project_path: 'namespace/project',
          id: 'main/app/models/user.rb',
          ref_type: nil
        })
      end

      it 'parses a nested project blob URL' do
        url = 'https://gitlab.com/parent/child/project/-/blob/main/README.md'
        result = service.send(:parse_blob_url, url)

        expect(result).to eq({
          project_path: 'parent/child/project',
          id: 'main/README.md',
          ref_type: nil
        })
      end

      it 'parses a raw URL' do
        url = 'https://gitlab.com/namespace/project/-/raw/v1.0/README.md'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('v1.0/README.md')
      end

      it 'parses a blame URL' do
        url = 'https://gitlab.com/namespace/project/-/blame/main/README.md'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('main/README.md')
      end

      it 'keeps a slashed ref and the path combined' do
        url = 'https://gitlab.com/namespace/project/-/blob/feature/my-branch/app/x.rb'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('feature/my-branch/app/x.rb')
      end

      it 'splits on the first blob segment' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/docs/-/blob/nested.md'
        result = service.send(:parse_blob_url, url)

        expect(result).to include(project_path: 'namespace/project', id: 'main/docs/-/blob/nested.md')
      end

      it 'ignores the fragment' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/README.md#L10-20'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('main/README.md')
      end

      it 'decodes percent-encoded path segments' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/app/models/user%20copy.rb'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('main/app/models/user copy.rb')
      end

      it 'preserves a plus sign in the path' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/c++/main.cpp'
        result = service.send(:parse_blob_url, url)

        expect(result[:id]).to eq('main/c++/main.cpp')
      end
    end

    context 'with a ref_type query parameter' do
      it 'returns heads' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/README.md?ref_type=heads'

        expect(service.send(:parse_blob_url, url)[:ref_type]).to eq('heads')
      end

      it 'returns tags' do
        url = 'https://gitlab.com/namespace/project/-/blob/v1.0/README.md?ref_type=tags'

        expect(service.send(:parse_blob_url, url)[:ref_type]).to eq('tags')
      end

      it 'ignores an unrecognised ref_type' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/README.md?ref_type=bogus'

        expect(service.send(:parse_blob_url, url)[:ref_type]).to be_nil
      end

      it 'ignores other query parameters' do
        url = 'https://gitlab.com/namespace/project/-/blob/main/README.md?plain=1'

        expect(service.send(:parse_blob_url, url)[:ref_type]).to be_nil
      end
    end

    context 'with invalid URLs' do
      it 'raises ArgumentError for a tree URL' do
        url = 'https://gitlab.com/namespace/project/-/tree/main/app'

        expect { service.send(:parse_blob_url, url) }
          .to raise_error(ArgumentError, /Invalid file URL format/)
      end

      it 'raises ArgumentError when the blob segment is missing' do
        url = 'https://gitlab.com/namespace/project'

        expect { service.send(:parse_blob_url, url) }
          .to raise_error(ArgumentError, /Invalid file URL format/)
      end

      it 'raises ArgumentError when nothing follows the blob segment' do
        url = 'https://gitlab.com/namespace/project/-/blob/'

        expect { service.send(:parse_blob_url, url) }
          .to raise_error(ArgumentError, /Invalid file URL format/)
      end

      it 'raises ArgumentError when the project path is missing' do
        url = 'https://gitlab.com/-/blob/main/README.md'

        expect { service.send(:parse_blob_url, url) }
          .to raise_error(ArgumentError, /Invalid file URL format/)
      end

      it 'raises ArgumentError for an invalid scheme' do
        expect { service.send(:parse_blob_url, 'ftp://gitlab.com/ns/p/-/blob/main/README.md') }
          .to raise_error(ArgumentError, /Invalid URL format/)
      end
    end

    context 'when the instance is served under a relative URL root' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
      end

      it 'strips the relative URL root from the project path' do
        url = 'https://gitlab.example.com/gitlab/namespace/project/-/blob/main/README.md'
        result = service.send(:parse_blob_url, url)

        expect(result).to include(project_path: 'namespace/project', id: 'main/README.md')
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
    end

    context 'with group URLs' do
      it 'resolves group from URL' do
        url = "https://gitlab.com/groups/#{group.full_path}"
        result = service.send(:resolve_parent_from_url, url)

        expect(result[:type]).to eq(:group)
        expect(result[:full_path]).to eq(group.full_path)
        expect(result[:record]).to eq(group)
      end
    end

    context 'with access control' do
      let_it_be(:private_project) { create(:project, :private) }

      it 'raises a uniform not-found error when user lacks access to project' do
        url = "https://gitlab.com/#{private_project.full_path}"

        expect { service.send(:resolve_parent_from_url, url) }
          .to raise_error(StandardError, /not found or inaccessible/)
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

      it 'resolves the same work item through its issue URL' do
        url = "https://gitlab.com/#{project.full_path}/-/issues/#{work_item.iid}"
        result = service.send(:resolve_work_item_from_url, url)

        expect(result).to eq(work_item.to_global_id.to_s)
      end
    end

    context 'with valid group work item URL' do
      it 'resolves work item and returns global ID' do
        url = "https://gitlab.com/groups/#{group.full_path}/-/work_items/#{group_work_item.iid}"

        allow(service).to receive(:find_work_item_in_parent!).with(group, group_work_item.iid)
          .and_return(group_work_item)

        result = service.send(:resolve_work_item_from_url, url)

        expect(result).to eq(group_work_item.to_global_id.to_s)
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

      it 'raises a uniform not-found error when user lacks access to parent' do
        url = "https://gitlab.com/#{private_project.full_path}/-/work_items/#{private_work_item.iid}"

        expect { service.send(:resolve_work_item_from_url, url) }
          .to raise_error(StandardError, /not found or inaccessible/)
      end
    end
  end
end
