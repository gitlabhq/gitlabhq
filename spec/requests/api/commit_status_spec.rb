require 'spec_helper'

describe API::CommitStatus, api: true do
  include ApiHelpers

  let!(:project) { create(:project) }
  let(:commit) { project.repository.commit }
  let(:commit_status) { create(:commit_status, commit: ci_commit) }
  let(:guest) { create_user(:guest) }
  let(:reporter) { create_user(:reporter) }
  let(:developer) { create_user(:developer) }
  let(:sha) { commit.id }


  describe "GET /projects/:id/repository/commits/:sha/statuses" do
    let(:get_url) { "/projects/#{project.id}/repository/commits/#{sha}/statuses" }

    context 'ci commit exists' do
      let!(:ci_commit) { project.ensure_ci_commit(commit.id) }

      it_behaves_like 'a paginated resources' do
        let(:request) { get api(get_url, reporter) }
      end

      context "reporter user" do
        let(:statuses_id) { json_response.map { |status| status['id'] } }

        def create_status(opts = {})
          create(:commit_status, { commit: ci_commit }.merge(opts))
        end

        let!(:status1) { create_status(status: 'running') }
        let!(:status2) { create_status(name: 'coverage', status: 'pending') }
        let!(:status3) { create_status(ref: 'develop', status: 'running', allow_failure: true) }
        let!(:status4) { create_status(name: 'coverage', status: 'success') }
        let!(:status5) { create_status(name: 'coverage', ref: 'develop', status: 'success') }
        let!(:status6) { create_status(status: 'success') }

        context 'latest commit statuses' do
          before { get api(get_url, reporter) }

          it 'returns latest commit statuses' do
            expect(response.status).to eq(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status3.id, status4.id, status5.id, status6.id)
            json_response.sort_by!{ |status| status['id'] }
            expect(json_response.map{ |status| status['allow_failure'] }).to eq([true, false, false, false])
          end
        end

        context 'all commit statuses' do
          before { get api(get_url, reporter), all: 1 }

          it 'returns all commit statuses' do
            expect(response.status).to eq(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status1.id, status2.id,
                                                   status3.id, status4.id,
                                                   status5.id, status6.id)
          end
        end

        context 'latest commit statuses for specific ref' do
          before { get api(get_url, reporter), ref: 'develop' }

          it 'returns latest commit statuses for specific ref' do
            expect(response.status).to eq(200)

            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status3.id, status5.id)
          end
        end

        context 'latest commit statues for specific name' do
          before { get api(get_url, reporter), name: 'coverage' }

          it 'return latest commit statuses for specific name' do
            expect(response.status).to eq(200)

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

      it "should not return project commits" do
        expect(response.status).to eq(403)
      end
    end

    context "unauthorized user" do
      before { get api(get_url) }

      it "should not return project commits" do
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects/:id/statuses/:sha' do
    let(:post_url) { "/projects/#{project.id}/statuses/#{sha}" }

    context 'developer user' do
      context 'only required parameters' do
        before { post api(post_url, developer), state: 'success' }

        it 'creates commit status' do
          expect(response.status).to eq(201)
          expect(json_response['sha']).to eq(commit.id)
          expect(json_response['status']).to eq('success')
          expect(json_response['name']).to eq('default')
          expect(json_response['ref']).to be_nil
          expect(json_response['target_url']).to be_nil
          expect(json_response['description']).to be_nil
        end
      end

      context 'with all optional parameters' do
        before do
          optional_params = { state: 'success', context: 'coverage',
                              ref: 'develop', target_url: 'url', description: 'test' }

          post api(post_url, developer), optional_params
        end

        it 'creates commit status' do
          expect(response.status).to eq(201)
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
          expect(response.status).to eq(400)
        end
      end

      context 'request without state' do
        before { post api(post_url, developer) }

        it 'does not create commit status' do
          expect(response.status).to eq(400)
        end
      end

      context 'invalid commit' do
        let(:sha) { 'invalid_sha' }
        before { post api(post_url, developer), state: 'running' }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end
      end
    end

    context 'reporter user' do
      before { post api(post_url, reporter) }

      it 'should not create commit status' do
        expect(response.status).to eq(403)
      end
    end

    context 'guest user' do
      before { post api(post_url, guest) }

      it 'should not create commit status' do
        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      before { post api(post_url) }

      it 'should not create commit status' do
        expect(response.status).to eq(401)
      end
    end
  end

  def create_user(access_level_trait)
    user = create(:user)
    create(:project_member, access_level_trait, user: user, project: project)
    user
  end
end
