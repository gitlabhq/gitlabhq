require 'spec_helper'

describe API::CommitStatuses, api: true do
  include ApiHelpers

  let!(:project) { create(:project) }
  let(:commit) { project.repository.commit }
  let(:commit_status) { create(:commit_status, pipeline: pipeline) }
  let(:guest) { create_user(:guest) }
  let(:reporter) { create_user(:reporter) }
  let(:developer) { create_user(:developer) }
  let(:sha) { commit.id }

  describe "GET /projects/:id/repository/commits/:sha/statuses" do
    let(:get_url) { "/projects/#{project.id}/repository/commits/#{sha}/statuses" }

    context 'ci commit exists' do
      let!(:master) { project.pipelines.create(sha: commit.id, ref: 'master') }
      let!(:develop) { project.pipelines.create(sha: commit.id, ref: 'develop') }

      it_behaves_like 'a paginated resources' do
        let(:request) { get api(get_url, reporter) }
      end

      context "reporter user" do
        let(:statuses_id) { json_response.map { |status| status['id'] } }

        def create_status(commit, opts = {})
          create(:commit_status, { pipeline: commit, ref: commit.ref }.merge(opts))
        end

        let!(:status1) { create_status(master, status: 'running') }
        let!(:status2) { create_status(master, name: 'coverage', status: 'pending') }
        let!(:status3) { create_status(develop, status: 'running', allow_failure: true) }
        let!(:status4) { create_status(master, name: 'coverage', status: 'success') }
        let!(:status5) { create_status(develop, name: 'coverage', status: 'success') }
        let!(:status6) { create_status(master, status: 'success') }

        context 'latest commit statuses' do
          before { get api(get_url, reporter) }

          it 'returns latest commit statuses' do
            expect(response).to have_http_status(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status3.id, status4.id, status5.id, status6.id)
            json_response.sort_by!{ |status| status['id'] }
            expect(json_response.map{ |status| status['allow_failure'] }).to eq([true, false, false, false])
          end
        end

        context 'all commit statuses' do
          before { get api(get_url, reporter), all: 1 }

          it 'returns all commit statuses' do
            expect(response).to have_http_status(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status1.id, status2.id,
                                                   status3.id, status4.id,
                                                   status5.id, status6.id)
          end
        end

        context 'latest commit statuses for specific ref' do
          before { get api(get_url, reporter), ref: 'develop' }

          it 'returns latest commit statuses for specific ref' do
            expect(response).to have_http_status(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status3.id, status5.id)
          end
        end

        context 'latest commit statues for specific name' do
          before { get api(get_url, reporter), name: 'coverage' }

          it 'return latest commit statuses for specific name' do
            expect(response).to have_http_status(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status4.id, status5.id)
          end
        end
      end
    end

    context 'ci commit does not exist' do
      before { get api(get_url, reporter) }

      it 'returns empty array' do
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response).to be_empty
      end
    end

    context "guest user" do
      before { get api(get_url, guest) }

      it "does not return project commits" do
        expect(response).to have_http_status(403)
      end
    end

    context "unauthorized user" do
      before { get api(get_url) }

      it "does not return project commits" do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/statuses/:sha' do
    let(:post_url) { "/projects/#{project.id}/statuses/#{sha}" }

    context 'developer user' do
      %w[pending running success failed canceled].each do |status|
        context "for #{status}" do
          context 'uses only required parameters' do
            it 'creates commit status' do
              post api(post_url, developer), state: status

              expect(response).to have_http_status(201)
              expect(json_response['sha']).to eq(commit.id)
              expect(json_response['status']).to eq(status)
              expect(json_response['name']).to eq('default')
              expect(json_response['ref']).not_to be_empty
              expect(json_response['target_url']).to be_nil
              expect(json_response['description']).to be_nil
            end
          end
        end
      end

      context 'transitions status from pending' do
        before do
          post api(post_url, developer), state: 'pending'
        end

        %w[running success failed canceled].each do |status|
          it "to #{status}" do
            expect { post api(post_url, developer), state: status }.not_to change { CommitStatus.count }

            expect(response).to have_http_status(201)
            expect(json_response['status']).to eq(status)
          end
        end
      end

      context 'with all optional parameters' do
        before do
          optional_params = { state: 'success', context: 'coverage',
                              ref: 'develop', target_url: 'url', description: 'test' }

          post api(post_url, developer), optional_params
        end

        it 'creates commit status' do
          expect(response).to have_http_status(201)
          expect(json_response['sha']).to eq(commit.id)
          expect(json_response['status']).to eq('success')
          expect(json_response['name']).to eq('coverage')
          expect(json_response['ref']).to eq('develop')
          expect(json_response['target_url']).to eq('url')
          expect(json_response['description']).to eq('test')
        end
      end

      context 'invalid status' do
        before { post api(post_url, developer), state: 'invalid' }

        it 'does not create commit status' do
          expect(response).to have_http_status(400)
        end
      end

      context 'request without state' do
        before { post api(post_url, developer) }

        it 'does not create commit status' do
          expect(response).to have_http_status(400)
        end
      end

      context 'invalid commit' do
        let(:sha) { 'invalid_sha' }
        before { post api(post_url, developer), state: 'running' }

        it 'returns not found error' do
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'reporter user' do
      before { post api(post_url, reporter) }

      it 'does not create commit status' do
        expect(response).to have_http_status(403)
      end
    end

    context 'guest user' do
      before { post api(post_url, guest) }

      it 'does not create commit status' do
        expect(response).to have_http_status(403)
      end
    end

    context 'unauthorized user' do
      before { post api(post_url) }

      it 'does not create commit status' do
        expect(response).to have_http_status(401)
      end
    end
  end

  def create_user(access_level_trait)
    user = create(:user)
    create(:project_member, access_level_trait, user: user, project: project)
    user
  end
end
