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
        expect(file_contents).to include("export const hasOrganizationScopedPaths")
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
            "import { hasOrganizationScopedPaths, splitProjectFullPath } from '~/lib/utils/path_helpers/utils';"
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

  if (hasOrganizationScopedPaths()) {
    return _organizationNamespaceProjectPreviewMarkdownPath(gon.current_organization.path, namespacePath, projectPath, ...args);
  }

  return _namespaceProjectPreviewMarkdownPath(namespacePath, projectPath, ...args);
            JS
          )
        end

        it 'generates group path helpers' do
          file_path = File.join(expected_base_path, 'group.js')
          expect(File).to exist(file_path)

          file_contents = File.read(file_path)
          expect(file_contents).to include("import { __jsr } from '~/lib/utils/path_helpers/core';")
          expect(file_contents).to include(
            "import { hasOrganizationScopedPaths } from '~/lib/utils/path_helpers/utils';"
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
  if (hasOrganizationScopedPaths()) {
    return _organizationEditGroupPath(gon.current_organization.path, ...args);
  }

  return _editGroupPath(...args);
            JS
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
