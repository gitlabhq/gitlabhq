# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::PackagePresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { "@#{project.root_namespace.path}/test" }
  let_it_be(:package1) { create(:npm_package, version: '2.0.4', project: project, name: package_name) }
  let_it_be(:package2) { create(:npm_package, version: '2.0.6', project: project, name: package_name) }
  let_it_be(:latest_package) { create(:npm_package, version: '2.0.11', project: project, name: package_name) }

  let(:packages) { project.packages.npm.with_name(package_name).last_of_each_version }
  let(:presenter) { described_class.new(package_name, packages) }

  describe '#versions' do
    subject { presenter.versions }

    shared_examples 'returning packages versions' do |expect_n_plus_one: false|
      context 'for packages without dependencies' do
        it { is_expected.to be_a(Hash) }
        it { expect(subject[package1.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
        it { expect(subject[package2.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }

        ::Packages::DependencyLink.dependency_types.keys.each do |dependency_type|
          it { expect(subject.dig(package1.version, dependency_type)).to be nil }
          it { expect(subject.dig(package2.version, dependency_type)).to be nil }
        end

        it 'avoids N+1 database queries' do
          check_n_plus_one(:versions, expect_it: expect_n_plus_one) do
            create_list(:npm_package, 5, project: project, name: package_name)
          end
        end
      end

      context 'for packages with dependencies' do
        ::Packages::DependencyLink.dependency_types.keys.each do |dependency_type|
          let_it_be("package_dependency_link_for_#{dependency_type}") { create(:packages_dependency_link, package: package1, dependency_type: dependency_type) }
        end

        it { is_expected.to be_a(Hash) }
        it { expect(subject[package1.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
        it { expect(subject[package2.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
        ::Packages::DependencyLink.dependency_types.keys.each do |dependency_type|
          it { expect(subject.dig(package1.version, dependency_type.to_s)).to be_any }
        end

        it 'avoids N+1 database queries' do
          check_n_plus_one(:versions, expect_it: expect_n_plus_one) do
            create_list(:npm_package, 5, project: project, name: package_name).each do |npm_package|
              ::Packages::DependencyLink.dependency_types.keys.each do |dependency_type|
                create(:packages_dependency_link, package: npm_package, dependency_type: dependency_type)
              end
            end
          end
        end
      end
    end

    it_behaves_like 'returning packages versions'

    context 'with npm_presenter_queries_tuning disabled' do
      before do
        stub_feature_flags(npm_presenter_queries_tuning: false)
      end

      it_behaves_like 'returning packages versions', expect_n_plus_one: true
    end
  end

  describe '#dist_tags' do
    subject { presenter.dist_tags }

    shared_examples 'returning packages tags' do
      context 'for packages without tags' do
        it { is_expected.to be_a(Hash) }
        it { expect(subject["latest"]).to eq(latest_package.version) }

        it 'avoids N+1 database queries' do
          check_n_plus_one(:dist_tags) do
            create_list(:npm_package, 5, project: project, name: package_name)
          end
        end
      end

      context 'for packages with tags' do
        let_it_be(:package_tag1) { create(:packages_tag, package: package1, name: 'release_a') }
        let_it_be(:package_tag2) { create(:packages_tag, package: package1, name: 'test_release') }
        let_it_be(:package_tag3) { create(:packages_tag, package: package2, name: 'release_b') }
        let_it_be(:package_tag4) { create(:packages_tag, package: latest_package, name: 'release_c') }
        let_it_be(:package_tag5) { create(:packages_tag, package: latest_package, name: 'latest') }

        it { is_expected.to be_a(Hash) }
        it { expect(subject[package_tag1.name]).to eq(package1.version) }
        it { expect(subject[package_tag2.name]).to eq(package1.version) }
        it { expect(subject[package_tag3.name]).to eq(package2.version) }
        it { expect(subject[package_tag4.name]).to eq(latest_package.version) }
        it { expect(subject[package_tag5.name]).to eq(latest_package.version) }

        it 'avoids N+1 database queries' do
          check_n_plus_one(:dist_tags) do
            create_list(:npm_package, 5, project: project, name: package_name).each_with_index do |npm_package, index|
              create(:packages_tag, package: npm_package, name: "tag_#{index}")
            end
          end
        end
      end
    end

    it_behaves_like 'returning packages tags'

    context 'with npm_presenter_queries_tuning disabled' do
      before do
        stub_feature_flags(npm_presenter_queries_tuning: false)
      end

      it_behaves_like 'returning packages tags'
    end
  end

  def check_n_plus_one(field, expect_it: false)
    pkgs = project.packages.npm.with_name(package_name).last_of_each_version.preload_files
    control = ActiveRecord::QueryRecorder.new { described_class.new(package_name, pkgs).public_send(field) }

    yield

    pkgs = project.packages.npm.with_name(package_name).last_of_each_version.preload_files

    if expect_it
      expect { described_class.new(package_name, pkgs).public_send(field) }.to exceed_query_limit(control)
    else
      expect { described_class.new(package_name, pkgs).public_send(field) }.not_to exceed_query_limit(control)
    end
  end
end
