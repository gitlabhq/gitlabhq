# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Pypi::SimpleIndexJsonPresenter, :aggregate_failures, feature_category: :package_registry do
  # Finder/scopes + each_batch require persisted records.
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Presenter operates on ActiveRecord relations and uses each_batch.
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package1) { create(:pypi_package, project: project, name: 'Foo') }
  let_it_be(:package2) { create(:pypi_package, project: project, name: 'bar') }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:packages) { Packages::Pypi::Package.for_projects(project) }

  describe '#body' do
    subject(:json) { Gitlab::Json.safe_parse(described_class.new(packages, project_or_group).body) }

    shared_examples_for 'pypi simple index json presenter' do
      it 'returns PEP 691 JSON with projects list' do
        expect(json['meta']).to include('api-version' => described_class::API_VERSION)
        expect(json['projects']).to be_an(Array)
        expect(json['projects']).not_to be_empty
        expect(json['projects']).to all(include('name'))

        names = json['projects'].pluck('name')
        expect(names).to include(package1.normalized_pypi_name, package2.normalized_pypi_name)
      end

      it 'returns unique sorted project names' do
        names = json['projects'].pluck('name')
        expect(names).to eq(names.uniq.sort)
      end

      it 'avoids n+1 database queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          described_class.new(Packages::Pypi::Package.for_projects(project).reload, project_or_group).body
        end

        # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Creating records is required to validate query count.
        create_list(:pypi_package, 5, project: project)
        # rubocop:enable RSpec/FactoryBot/AvoidCreate

        expect { described_class.new(Packages::Pypi::Package.for_projects(project).reload, project_or_group).body }
          .to issue_same_number_of_queries_as(control)
      end
    end

    context 'for project' do
      let(:project_or_group) { project }

      it_behaves_like 'pypi simple index json presenter'
    end

    context 'for group' do
      let(:project_or_group) { group }

      it_behaves_like 'pypi simple index json presenter'
    end

    context 'with package files pending destruction' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted records with pending_destruction state.
      let_it_be(:package_pending_destruction) do
        create(:pypi_package, :pending_destruction, project: project, name: 'package_pending_destruction')
      end
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      let(:project_or_group) { project }

      it 'does not include pending destruction packages' do
        names = json['projects'].pluck('name')
        expect(names).not_to include(package_pending_destruction.normalized_pypi_name)
      end
    end
  end
end
