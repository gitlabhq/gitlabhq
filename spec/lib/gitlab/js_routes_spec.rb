# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JsRoutes, feature_category: :tooling do
  describe '.generate!' do
    let_it_be(:expected_base_path) do
      Rails.root.join('app/assets/javascripts/lib/utils/path_helpers')
    end

    describe 'outputted files' do
      before_all do
        described_class.generate!
      end

      it 'outputs utils.js file' do
        file_path = File.join(expected_base_path, 'utils.js')
        expect(File).to exist(File.join(expected_base_path, 'utils.js'))

        file_contents = File.read(file_path)
        expect(file_contents).to include("const isOptionsObject")
        expect(file_contents).to include("export const resolveOrganizationScope")
        expect(file_contents).to include("export const splitProjectFullPath")
      end

      it 'outputs core.js file' do
        file_path = File.join(expected_base_path, 'core.js')
        expect(File).to exist(file_path)

        expect(File.read(file_path)).to include("export { __jsr };")
      end

      describe 'path helpers are split into multiple files by namespace' do
        it 'generates project path helpers' do
          file_path = File.join(expected_base_path, 'project.js')
          expect(File).to exist(file_path)

          file_contents = File.read(file_path)
          expect(file_contents).to include("import { __jsr } from '~/lib/utils/path_helpers/core';")
          expect(file_contents).to include(
            "import { resolveOrganizationScope, splitProjectFullPath } from '~/lib/utils/path_helpers/utils';"
          )
          expect(file_contents).to include(
            "export const projectPreviewMarkdownPath = /*#__PURE__*/ (projectFullPath, ...args) => {"
          )
          expect(file_contents).to include(
            "const _organizationNamespaceProjectPreviewMarkdownPath = /*#__PURE__*/ __jsr.r("
          )
          expect(file_contents).to include(
            "const _namespaceProjectPreviewMarkdownPath = /*#__PURE__*/ __jsr.r("
          )
          expect(file_contents).to include(
            <<-JS
  const { namespacePath, projectPath } = splitProjectFullPath(projectFullPath);
  const { organizationPath, routeArgs } = resolveOrganizationScope(args);

  if (organizationPath) {
    return _organizationNamespaceProjectPreviewMarkdownPath(organizationPath, namespacePath, projectPath, ...routeArgs);
  }

  return _namespaceProjectPreviewMarkdownPath(namespacePath, projectPath, ...routeArgs);
            JS
          )
        end

        it 'generates group path helpers' do
          file_path = File.join(expected_base_path, 'group.js')
          expect(File).to exist(file_path)

          file_contents = File.read(file_path)
          expect(file_contents).to include("import { __jsr } from '~/lib/utils/path_helpers/core';")
          expect(file_contents).to include(
            "import { resolveOrganizationScope } from '~/lib/utils/path_helpers/utils';"
          )
          expect(file_contents).to include(
            "export const editGroupPath = /*#__PURE__*/ (...args) => {"
          )
          expect(file_contents).to include(
            "const _organizationEditGroupPath = /*#__PURE__*/ __jsr.r("
          )
          expect(file_contents).to include(
            "const _editGroupPath = /*#__PURE__*/ __jsr.r("
          )
          expect(file_contents).to include(
            <<-JS
  const { organizationPath, routeArgs } = resolveOrganizationScope(args);

  if (organizationPath) {
    return _organizationEditGroupPath(organizationPath, ...routeArgs);
  }

  return _editGroupPath(...routeArgs);
            JS
          )
        end

        it 'annotates each helper with its equivalent Rails route metadata' do
          file_path = File.join(expected_base_path, 'project.js')

          file_contents = File.read(file_path)
          expect(file_contents).to include(" * - href: `/:project_full_path/-/preview_markdown(.:format)`")
          expect(file_contents).to include(" * - Path helper: `project_preview_markdown_path`")
          expect(file_contents).to include(" * - URL helper: `project_preview_markdown_url`")
          expect(file_contents).to include(" * - controller#action: `projects#preview_markdown`")
        end

        it 'documents organizationPath as an options key on organization scoped helpers' do
          file_contents = File.read(File.join(expected_base_path, 'group.js'))

          expect(file_contents).to include(
            <<-JS
 * @param {object | undefined} options
 * @param {string | null | undefined} options.organizationPath Path of organization to nest under. Pass `null` to remove path from URL params when outside of an organization data context.
 * @returns {string} route path
            JS
          )
        end

        it 'does not document organizationPath on helpers without an organization scoped counterpart' do
          file_contents = File.read(File.join(expected_base_path, 'organizations.js'))

          expect(file_contents).not_to include('options.organizationPath')
        end

        it 'generates organizations path helpers as unscoped' do
          file_path = File.join(expected_base_path, 'organizations.js')
          expect(File).to exist(file_path)

          file_contents = File.read(file_path)
          expect(file_contents).to include("import { __jsr } from '~/lib/utils/path_helpers/core';")
          expect(file_contents).not_to include('resolveOrganizationScope')
          expect(file_contents).not_to include('splitProjectFullPath')
          expect(file_contents).to include(
            "export const organizationPath = /*#__PURE__*/ __jsr.r("
          )
        end
      end
    end

    describe 'route_source_locations' do
      before do
        allow(described_class).to receive(:generate_path_helpers!).and_return(nil)
        allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations=)
        allow(Rails.application).to receive(:reload_routes!)
      end

      context 'when route_source_locations is disabled (production)' do
        before do
          allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations).and_return(false)
        end

        it 'temporarily enables route_source_locations, reloads routes, and restores setting after generation' do
          described_class.generate!

          expect(ActionDispatch::Routing::Mapper).to have_received(:route_source_locations=).with(true).ordered
          expect(Rails.application).to have_received(:reload_routes!).ordered
          expect(described_class).to have_received(:generate_path_helpers!).twice.ordered
          expect(ActionDispatch::Routing::Mapper).to have_received(:route_source_locations=).with(false).ordered
        end
      end

      context 'when route_source_locations is enabled (development)' do
        before do
          allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations).and_return(true)
        end

        it 'does not reload routes to avoid issues with caching' do
          described_class.generate!

          expect(Rails.application).not_to have_received(:reload_routes!)
        end
      end
    end
  end
end
