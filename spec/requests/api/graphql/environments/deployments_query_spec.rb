# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments Deployments query' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }

  let(:user) { developer }

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  context 'when there are deployments in the environment' do
    let_it_be(:finished_deployment_old) do
      create(:deployment, :success, environment: environment, project: project, finished_at: 2.days.ago)
    end

    let_it_be(:finished_deployment_new) do
      create(:deployment, :success, environment: environment, project: project, finished_at: 1.day.ago)
    end

    let_it_be(:upcoming_deployment_old) do
      create(:deployment, :created, environment: environment, project: project, created_at: 2.hours.ago)
    end

    let_it_be(:upcoming_deployment_new) do
      create(:deployment, :created, environment: environment, project: project, created_at: 1.hour.ago)
    end

    let_it_be(:other_environment) { create(:environment, project: project) }
    let_it_be(:other_deployment) { create(:deployment, :success, environment: other_environment, project: project) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environment(name: "#{environment.name}") {
              deployments {
                nodes {
                  id
                  iid
                  ref
                  tag
                  sha
                  createdAt
                  updatedAt
                  finishedAt
                  status
                }
              }
            }
          }
        }
      )
    end

    it 'returns all deployments of the environment' do
      deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

      expect(deployments.count).to eq(4)
    end

    context 'when query last deployment' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [SUCCESS], orderBy: { finishedAt: DESC }, first: 1) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployment' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(1)
        expect(deployments[0]['iid']).to eq(finished_deployment_new.iid.to_s)
      end
    end

    context 'when query latest upcoming deployment' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [CREATED RUNNING BLOCKED], orderBy: { createdAt: DESC }, first: 1) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployment' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(1)
        expect(deployments[0]['iid']).to eq(upcoming_deployment_new.iid.to_s)
      end
    end

    context 'when query finished deployments in descending order' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [SUCCESS FAILED CANCELED], orderBy: { finishedAt: DESC }) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployments' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(2)
        expect(deployments[0]['iid']).to eq(finished_deployment_new.iid.to_s)
        expect(deployments[1]['iid']).to eq(finished_deployment_old.iid.to_s)
      end
    end

    context 'when query finished deployments in ascending order' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [SUCCESS FAILED CANCELED], orderBy: { finishedAt: ASC }) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployments' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(2)
        expect(deployments[0]['iid']).to eq(finished_deployment_old.iid.to_s)
        expect(deployments[1]['iid']).to eq(finished_deployment_new.iid.to_s)
      end
    end

    context 'when query upcoming deployments in descending order' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [CREATED RUNNING BLOCKED], orderBy: { createdAt: DESC }) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployments' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(2)
        expect(deployments[0]['iid']).to eq(upcoming_deployment_new.iid.to_s)
        expect(deployments[1]['iid']).to eq(upcoming_deployment_old.iid.to_s)
      end
    end

    context 'when query upcoming deployments in ascending order' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [CREATED RUNNING BLOCKED], orderBy: { createdAt: ASC }) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'returns deployments' do
        deployments = subject.dig('data', 'project', 'environment', 'deployments', 'nodes')

        expect(deployments.count).to eq(2)
        expect(deployments[0]['iid']).to eq(upcoming_deployment_old.iid.to_s)
        expect(deployments[1]['iid']).to eq(upcoming_deployment_new.iid.to_s)
      end
    end

    context 'when query last deployments of multiple environments' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environments {
                nodes {
                  name
                  deployments(statuses: [SUCCESS], orderBy: { finishedAt: DESC }, first: 1) {
                    nodes {
                      iid
                    }
                  }
                }
              }
            }
          }
        )
      end

      it 'returnes an error for preventing N+1 queries' do
        expect(subject['errors'][0]['message']).to include('exceeds max complexity')
      end
    end

    context 'when query finished and upcoming deployments together' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [CREATED SUCCESS]) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'raises an error' do
        expect { subject }.to raise_error(DeploymentsFinder::InefficientQueryError)
      end
    end

    context 'when multiple orderBy input are specified' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(orderBy: { finishedAt: DESC, createdAt: ASC }) {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        )
      end

      it 'raises an error' do
        expect(subject['errors'][0]['message']).to include('orderBy parameter must contain one key-value pair.')
      end
    end

    context 'when user is guest' do
      let(:user) { guest }

      it 'returns nothing' do
        expect(subject['data']['project']['environment']).to be_nil
      end
    end

    describe 'sorting and pagination' do
      let(:data_path) { [:project, :environment, :deployments] }
      let(:current_user) { user }

      def pagination_query(params)
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                deployments(statuses: [SUCCESS], #{params}) {
                  nodes {
                    iid
                  }
                  pageInfo {
                    startCursor
                    endCursor
                    hasNextPage
                    hasPreviousPage
                  }
                }
              }
            }
          }
        )
      end

      def pagination_results_data(nodes)
        nodes.map { |deployment| deployment['iid'].to_i }
      end

      context 'when sorting by finished_at in ascending order' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_argument) { graphql_args(orderBy: { finishedAt: :ASC }) }
          let(:first_param) { 2 }
          let(:all_records) { [finished_deployment_old.iid, finished_deployment_new.iid] }
        end
      end

      context 'when sorting by finished_at in descending order' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_argument) { graphql_args(orderBy: { finishedAt: :DESC }) }
          let(:first_param) { 2 }
          let(:all_records) { [finished_deployment_new.iid, finished_deployment_old.iid] }
        end
      end
    end
  end
end
