shared_examples 'an unauthorized API user' do
  it { is_expected.to eq(403) }
end

shared_examples 'time tracking endpoints' do |issuable_name|
  issuable_collection_name = issuable_name.pluralize

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/time_estimate" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", non_member), duration: '1w') }

      it_behaves_like 'an unauthorized API user'
    end

    it "sets the time estimate for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), duration: '1w'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['human_time_estimate']).to eq('1w')
    end

    describe 'updating the current estimate' do
      before do
        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), duration: '1w'
      end

      context 'when duration has a bad format' do
        it 'does not modify the original estimate' do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), duration: 'foo'

          expect(response).to have_gitlab_http_status(400)
          expect(issuable.reload.human_time_estimate).to eq('1w')
        end
      end

      context 'with a valid duration' do
        it 'updates the estimate' do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), duration: '3w1h'

          expect(response).to have_gitlab_http_status(200)
          expect(issuable.reload.human_time_estimate).to eq('3w 1h')
        end
      end
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/reset_time_estimate" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_time_estimate", non_member)) }

      it_behaves_like 'an unauthorized API user'
    end

    it "resets the time estimate for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_time_estimate", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['time_estimate']).to eq(0)
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/add_spent_time" do
    context 'with an unauthorized user' do
      subject do
        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", non_member),
             duration: '2h'
      end

      it_behaves_like 'an unauthorized API user'
    end

    it "add spent time for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user),
           duration: '2h'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['human_total_time_spent']).to eq('2h')
    end

    context 'when subtracting time' do
      it 'subtracts time of the total spent time' do
        issuable.update_attributes!(spend_time: { duration: 7200, user_id: user.id })

        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user),
             duration: '-1h'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['total_time_spent']).to eq(3600)
      end
    end

    context 'when time to subtract is greater than the total spent time' do
      it 'does not modify the total time spent' do
        issuable.update_attributes!(spend_time: { duration: 7200, user_id: user.id })

        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user),
             duration: '-1w'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['time_spent'].first).to match(/exceeds the total time spent/)
      end
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/reset_spent_time" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_spent_time", non_member)) }

      it_behaves_like 'an unauthorized API user'
    end

    it "resets spent time for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_spent_time", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['total_time_spent']).to eq(0)
    end
  end

  describe "GET /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/time_stats" do
    it "returns the time stats for #{issuable_name}" do
      issuable.update_attributes!(spend_time: { duration: 1800, user_id: user.id },
                                  time_estimate: 3600)

      get api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_stats", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['total_time_spent']).to eq(1800)
      expect(json_response['time_estimate']).to eq(3600)
    end
  end
end
