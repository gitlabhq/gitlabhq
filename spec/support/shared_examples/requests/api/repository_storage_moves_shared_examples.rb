# frozen_string_literal: true

RSpec.shared_examples 'repository_storage_moves API' do |container_type|
  include AccessMatchersForRequest

  let_it_be(:user) { create(:admin) }

  shared_examples 'get single container repository storage move' do
    let(:repository_storage_move_id) { storage_move.id }

    def get_container_repository_storage_move
      get api(url, user, admin_mode: user.admin?)
    end

    it 'returns a container repository storage move', :aggregate_failures do
      get_container_repository_storage_move

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema("public_api/v4/#{container_type.singularize}_repository_storage_move")
      expect(json_response['id']).to eq(storage_move.id)
      expect(json_response['state']).to eq(storage_move.human_state_name)
    end

    context 'non-existent container repository storage move' do
      let(:repository_storage_move_id) { non_existing_record_id }

      it 'returns not found' do
        get_container_repository_storage_move

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'permissions' do
      it { expect { get_container_repository_storage_move }.to be_allowed_for(:admin) }
      it { expect { get_container_repository_storage_move }.to be_denied_for(:user) }
    end
  end

  shared_examples 'get container repository storage move list' do
    def get_container_repository_storage_moves
      get api(url, user, admin_mode: user.admin?)
    end

    it 'returns container repository storage moves', :aggregate_failures do
      get_container_repository_storage_moves

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema("public_api/v4/#{container_type.singularize}_repository_storage_moves")
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(storage_move.id)
      expect(json_response.first['state']).to eq(storage_move.human_state_name)
    end

    it 'avoids N+1 queries', :request_store do
      # prevent `let` from polluting the control
      get_container_repository_storage_moves

      control = ActiveRecord::QueryRecorder.new { get_container_repository_storage_moves }

      create(repository_storage_move_factory, :scheduled, container: container)

      expect { get_container_repository_storage_moves }.not_to exceed_query_limit(control)
    end

    it 'returns the most recently created first' do
      storage_move_oldest = create(repository_storage_move_factory, :scheduled, container: container, created_at: 2.days.ago)
      storage_move_middle = create(repository_storage_move_factory, :scheduled, container: container, created_at: 1.day.ago)

      get_container_repository_storage_moves

      json_ids = json_response.pluck('id')
      expect(json_ids).to eq([storage_move.id, storage_move_middle.id, storage_move_oldest.id])
    end

    describe 'permissions' do
      it { expect { get_container_repository_storage_moves }.to be_allowed_for(:admin) }
      it { expect { get_container_repository_storage_moves }.to be_denied_for(:user) }
    end
  end

  shared_examples 'post single container repository storage move' do
    let(:url) { "/#{container_type}/#{container_id}/repository_storage_moves" }
    let(:container_id) { container.id }
    let(:destination_storage_name) { 'test_second_storage' }

    def create_container_repository_storage_move
      post api(url, user, admin_mode: user.admin?), params: { destination_storage_name: destination_storage_name }
    end

    before do
      stub_storage_settings('test_second_storage' => {})
    end

    it 'schedules a container repository storage move' do
      create_container_repository_storage_move

      storage_move = container.repository_storage_moves.last

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema("public_api/v4/#{container_type.singularize}_repository_storage_move")
      expect(json_response['id']).to eq(storage_move.id)
      expect(json_response['state']).to eq('scheduled')
      expect(json_response['source_storage_name']).to eq('default')
      expect(json_response['destination_storage_name']).to eq(destination_storage_name)
    end

    describe 'permissions' do
      it { expect { create_container_repository_storage_move }.to be_allowed_for(:admin) }
      it { expect { create_container_repository_storage_move }.to be_denied_for(:user) }
    end

    context 'destination_storage_name is missing' do
      let(:destination_storage_name) { nil }

      it 'schedules a container repository storage move' do
        create_container_repository_storage_move

        storage_move = container.repository_storage_moves.last

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema("public_api/v4/#{container_type.singularize}_repository_storage_move")
        expect(json_response['id']).to eq(storage_move.id)
        expect(json_response['state']).to eq('scheduled')
        expect(json_response['source_storage_name']).to eq('default')
        expect(json_response['destination_storage_name']).to be_present
      end
    end

    context 'when container does not exist' do
      let(:container_id) { non_existing_record_id }

      it 'returns not found' do
        create_container_repository_storage_move

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /#{container_type}/:id/repository_storage_moves" do
    let(:container_id) { container.id }
    let(:url) { "/#{container_type}/#{container_id}/repository_storage_moves" }

    it_behaves_like 'get container repository storage move list'

    context 'non-existent container' do
      let(:container_id) { non_existing_record_id }

      it 'returns not found' do
        get api(url, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /#{container_type}/:id/repository_storage_moves/:repository_storage_move_id" do
    let(:container_id) { container.id }
    let(:url) { "/#{container_type}/#{container_id}/repository_storage_moves/#{repository_storage_move_id}" }

    it_behaves_like 'get single container repository storage move'

    context 'non-existent container' do
      let(:container_id) { non_existing_record_id }
      let(:repository_storage_move_id) { storage_move.id }

      it 'returns not found' do
        get api(url, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /#{container_type.singularize}_repository_storage_moves" do
    it_behaves_like 'get container repository storage move list' do
      let(:url) { "/#{container_type.singularize}_repository_storage_moves" }
    end
  end

  describe "GET /#{container_type.singularize}_repository_storage_moves/:repository_storage_move_id" do
    it_behaves_like 'get single container repository storage move' do
      let(:url) { "/#{container_type.singularize}_repository_storage_moves/#{repository_storage_move_id}" }
    end
  end

  describe "POST /#{container_type}/:id/repository_storage_moves", :aggregate_failures do
    it_behaves_like 'post single container repository storage move'
  end

  describe "POST /#{container_type.singularize}_repository_storage_moves" do
    let(:url) { "/#{container_type.singularize}_repository_storage_moves" }
    let(:source_storage_name) { 'default' }
    let(:destination_storage_name) { 'test_second_storage' }

    def create_container_repository_storage_moves
      post api(url, user, admin_mode: user.admin?), params: {
        source_storage_name: source_storage_name,
        destination_storage_name: destination_storage_name
      }
    end

    before do
      stub_storage_settings('test_second_storage' => {})
    end

    it 'schedules the worker' do
      expect(bulk_worker_klass).to receive(:perform_async).with(source_storage_name, destination_storage_name)

      create_container_repository_storage_moves

      expect(response).to have_gitlab_http_status(:accepted)
    end

    context 'source_storage_name is invalid' do
      let(:destination_storage_name) { 'not-a-real-storage' }

      it 'gives an error' do
        create_container_repository_storage_moves

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'destination_storage_name is missing' do
      let(:destination_storage_name) { nil }

      it 'schedules the worker' do
        expect(bulk_worker_klass).to receive(:perform_async).with(source_storage_name, destination_storage_name)

        create_container_repository_storage_moves

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    context 'destination_storage_name is invalid' do
      let(:destination_storage_name) { 'not-a-real-storage' }

      it 'gives an error' do
        create_container_repository_storage_moves

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    describe 'normal user' do
      it { expect { create_container_repository_storage_moves }.to be_denied_for(:user) }
    end
  end
end
