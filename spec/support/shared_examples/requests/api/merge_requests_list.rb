shared_examples 'merge requests list' do
  context 'when unauthenticated' do
    it 'returns merge requests for public projects' do
      get api(endpoint_path)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
    end
  end

  context 'when authenticated' do
    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new do
        get api(endpoint_path, user)
      end

      create(:merge_request, state: 'closed', milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: 'Test', created_at: base_time)

      create(:merge_request, milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: 'Test', created_at: base_time)

      expect do
        get api(endpoint_path, user)
      end.not_to exceed_query_limit(control)
    end

    it 'returns an array of all merge_requests' do
      get api(endpoint_path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(4)
      expect(json_response.last['title']).to eq(merge_request.title)
      expect(json_response.last).to have_key('web_url')
      expect(json_response.last['sha']).to eq(merge_request.diff_head_sha)
      expect(json_response.last['merge_commit_sha']).to be_nil
      expect(json_response.last['merge_commit_sha']).to eq(merge_request.merge_commit_sha)
      expect(json_response.last['downvotes']).to eq(1)
      expect(json_response.last['upvotes']).to eq(1)
      expect(json_response.last['labels']).to eq([label2.title, label.title])
      expect(json_response.first['title']).to eq(merge_request_merged.title)
      expect(json_response.first['sha']).to eq(merge_request_merged.diff_head_sha)
      expect(json_response.first['merge_commit_sha']).not_to be_nil
      expect(json_response.first['merge_commit_sha']).to eq(merge_request_merged.merge_commit_sha)
    end

    it 'returns an array of all merge_requests using simple mode' do
      path = endpoint_path + '?view=simple'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response.last.keys).to match_array(%w(id iid title web_url created_at description project_id state updated_at))
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(4)
      expect(json_response.last['iid']).to eq(merge_request.iid)
      expect(json_response.last['title']).to eq(merge_request.title)
      expect(json_response.last).to have_key('web_url')
      expect(json_response.first['iid']).to eq(merge_request_merged.iid)
      expect(json_response.first['title']).to eq(merge_request_merged.title)
      expect(json_response.first).to have_key('web_url')
    end

    it 'returns an array of all merge_requests' do
      path = endpoint_path + '?state'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(4)
      expect(json_response.last['title']).to eq(merge_request.title)
    end

    it 'returns an array of open merge_requests' do
      path = endpoint_path + '?state=opened'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.last['title']).to eq(merge_request.title)
    end

    it 'returns an array of closed merge_requests' do
      path = endpoint_path + '?state=closed'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['title']).to eq(merge_request_closed.title)
    end

    it 'returns an array of merged merge_requests' do
      path = endpoint_path + '?state=merged'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['title']).to eq(merge_request_merged.title)
    end

    it 'matches V4 response schema' do
      get api(endpoint_path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/merge_requests')
    end

    it 'returns an empty array if no issue matches milestone' do
      get api(endpoint_path, user), milestone: '1.0.0'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if milestone does not exist' do
      get api(endpoint_path, user), milestone: 'foo'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an array of merge requests in given milestone' do
      get api(endpoint_path, user), milestone: '0.9'

      closed_issues = json_response.select { |mr| mr['id'] == merge_request_closed.id }
      expect(closed_issues.length).to eq(1)
      expect(closed_issues.first['title']).to eq merge_request_closed.title
    end

    it 'returns an array of merge requests matching state in milestone' do
      get api(endpoint_path, user), milestone: '0.9', state: 'closed'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(merge_request_closed.id)
    end

    it 'returns an array of labeled merge requests' do
      path = endpoint_path + "?labels=#{label.title}"

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([label2.title, label.title])
    end

    it 'returns an array of labeled merge requests where all labels match' do
      path = endpoint_path + "?labels=#{label.title},foo,bar"

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if no merge request matches labels' do
      path = endpoint_path + '?labels=foo,bar'

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an array of labeled merge requests that are merged for a milestone' do
      bug_label = create(:label, title: 'bug', color: '#FFAABB', project: project)

      mr1 = create(:merge_request, state: 'merged', source_project: project, target_project: project, milestone: milestone)
      mr2 = create(:merge_request, state: 'merged', source_project: project, target_project: project, milestone: milestone1)
      mr3 = create(:merge_request, state: 'closed', source_project: project, target_project: project, milestone: milestone1)
      _mr = create(:merge_request, state: 'merged', source_project: project, target_project: project, milestone: milestone1)

      create(:label_link, label: bug_label, target: mr1)
      create(:label_link, label: bug_label, target: mr2)
      create(:label_link, label: bug_label, target: mr3)

      path = endpoint_path + "?labels=#{bug_label.title}&milestone=#{milestone1.title}&state=merged"

      get api(path, user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(mr2.id)
    end

    context 'with ordering' do
      before do
        @mr_later = mr_with_later_created_and_updated_at_time
        @mr_earlier = mr_with_earlier_created_and_updated_at_time
      end

      it 'returns an array of merge_requests in ascending order' do
        path = endpoint_path + '?sort=asc'

        get api(path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(4)
        response_dates = json_response.map { |merge_request| merge_request['created_at'] }
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'returns an array of merge_requests in descending order' do
        path = endpoint_path + '?sort=desc'

        get api(path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(4)
        response_dates = json_response.map { |merge_request| merge_request['created_at'] }
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'returns an array of merge_requests ordered by updated_at' do
        path = endpoint_path + '?order_by=updated_at'

        get api(path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(4)
        response_dates = json_response.map { |merge_request| merge_request['updated_at'] }
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'returns an array of merge_requests ordered by created_at' do
        path = endpoint_path + '?order_by=created_at&sort=asc'

        get api(path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(4)
        response_dates = json_response.map { |merge_request| merge_request['created_at'] }
        expect(response_dates).to eq(response_dates.sort)
      end
    end

    context 'source_branch param' do
      it 'returns merge requests with the given source branch' do
        get api(endpoint_path, user), source_branch: merge_request_closed.source_branch, state: 'all'

        expect_response_contain_exactly(merge_request_closed, merge_request_merged, merge_request_locked)
      end
    end

    context 'target_branch param' do
      it 'returns merge requests with the given target branch' do
        get api(endpoint_path, user), target_branch: merge_request_closed.target_branch, state: 'all'

        expect_response_contain_exactly(merge_request_closed, merge_request_merged, merge_request_locked)
      end
    end
  end
end
