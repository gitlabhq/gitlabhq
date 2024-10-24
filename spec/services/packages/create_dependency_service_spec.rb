# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::CreateDependencyService, feature_category: :package_registry do
  describe '#execute' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:version) { '1.0.1' }
    let_it_be(:package_name) { "@#{namespace.path}/my-app" }

    context 'when packages are published' do
      let(:json_file) { 'packages/npm/payload.json' }
      let(:params) do
        Gitlab::Json.parse(fixture_file(json_file)
                .gsub('@root/npm-test', package_name)
                .gsub('1.0.1', version))
                .with_indifferent_access
      end

      let(:package_version) { params[:versions].each_key.first }
      let(:dependencies) { params[:versions][package_version] }
      let(:package) { create(:npm_package) }
      let(:dependency_names) { package.dependency_links.flat_map(&:dependency).map(&:name).sort }
      let(:dependency_link_types) { package.dependency_links.map(&:dependency_type).sort }

      subject { described_class.new(package, dependencies).execute }

      it 'creates dependencies and links' do
        expect(Packages::Dependency)
            .to receive(:ids_for_package_project_id_names_and_version_patterns)
            .once
            .and_call_original

        expect { subject }
          .to change { Packages::Dependency.count }.by(1)
          .and change { Packages::DependencyLink.count }.by(1)
        expect(dependency_names).to match_array(%w[express])
        expect(dependency_link_types).to match_array(%w[dependencies])
      end

      context 'with repeated packages' do
        let(:json_file) { 'packages/npm/payload_with_duplicated_packages.json' }

        it 'creates dependencies and links' do
          expect(Packages::Dependency)
            .to receive(:ids_for_package_project_id_names_and_version_patterns)
            .exactly(4).times
            .and_call_original

          expect { subject }
            .to change { Packages::Dependency.count }.by(4)
            .and change { Packages::DependencyLink.count }.by(6)
          expect(dependency_names).to match_array(%w[d3 d3 d3 dagre-d3 dagre-d3 express])
          expect(dependency_link_types).to match_array(%w[bundleDependencies dependencies dependencies devDependencies devDependencies peerDependencies])
        end
      end

      context 'with dependencies bulk insert conflicts' do
        let_it_be(:rows) { [{ name: 'express', version_pattern: '^4.16.4' }] }

        it 'creates dependences and links' do
          original_bulk_insert = ::ApplicationRecord.method(:legacy_bulk_insert)
          expect(::ApplicationRecord)
            .to receive(:legacy_bulk_insert) do |table, rows, return_ids: false, disable_quote: [], on_conflict: nil|
              call_count = table == Packages::Dependency.table_name ? 2 : 1
              call_count.times { original_bulk_insert.call(table, rows, return_ids: return_ids, disable_quote: disable_quote, on_conflict: on_conflict) }
            end.twice
          expect(Packages::Dependency)
            .to receive(:ids_for_package_project_id_names_and_version_patterns)
            .twice
            .and_call_original

          expect { subject }
            .to change { Packages::Dependency.count }.by(1)
            .and change { Packages::DependencyLink.count }.by(1)
          expect(dependency_names).to match_array(%w[express])
          expect(dependency_link_types).to match_array(%w[dependencies])
        end
      end

      context 'with existing dependencies' do
        let(:name_and_version_pattern) { dependencies['dependencies'].to_a.flatten }

        let!(:dependency) do
          create(
            :packages_dependency,
            name: name_and_version_pattern[0],
            version_pattern: name_and_version_pattern[1],
            project: project
          )
        end

        shared_examples 'reuses dependencies' do
          it do
            expect { subject }
              .to not_change { Packages::Dependency.count }
              .and change { Packages::DependencyLink.count }.by(1)
          end
        end

        context 'with project' do
          context 'in the same project' do
            let(:project) { package.project }

            it_behaves_like 'reuses dependencies'
          end

          context 'in the different project' do
            let_it_be(:project) { create(:project) }

            it 'does not reuse them' do
              expect { subject }
                .to change { Packages::Dependency.count }.by(1)
                .and change { Packages::DependencyLink.count }.by(1)
            end
          end
        end
      end

      context 'with a dependency not described with a hash' do
        let(:invalid_dependencies) { dependencies.tap { |d| d['bundleDependencies'] = false } }

        subject { described_class.new(package, invalid_dependencies).execute }

        it 'creates dependencies and links' do
          expect(Packages::Dependency)
              .to receive(:ids_for_package_project_id_names_and_version_patterns)
              .once
              .and_call_original

          expect { subject }
            .to change { Packages::Dependency.count }.by(1)
            .and change { Packages::DependencyLink.count }.by(1)
          expect(dependency_names).to match_array(%w[express])
          expect(dependency_link_types).to match_array(%w[dependencies])
        end
      end
    end
  end
end
