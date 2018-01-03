shared_examples 'milestone tabs' do
  def go(path, extra_params = {})
    params =
      case milestone
      when DashboardMilestone
        { id: milestone.safe_title, title: milestone.title }
      when GroupMilestone
        { group_id: group.to_param, id: milestone.safe_title, title: milestone.title }
      else
        { namespace_id: project.namespace.to_param, project_id: project, id: milestone.iid }
      end

    get path, params.merge(extra_params)
  end

  describe '#merge_requests' do
    context 'as html' do
      before do
        go(:merge_requests, format: 'html')
      end

      it 'redirects to milestone#show' do
        expect(response).to redirect_to(milestone_path)
      end
    end

    context 'as json' do
      before do
        go(:merge_requests, format: 'json')
      end

      it 'renders the merge requests tab template to a string' do
        expect(response).to render_template('shared/milestones/_merge_requests_tab')
        expect(json_response).to have_key('html')
      end
    end
  end

  describe '#participants' do
    context 'as html' do
      before do
        go(:participants, format: 'html')
      end

      it 'redirects to milestone#show' do
        expect(response).to redirect_to(milestone_path)
      end
    end

    context 'as json' do
      before do
        go(:participants, format: 'json')
      end

      it 'renders the participants tab template to a string' do
        expect(response).to render_template('shared/milestones/_participants_tab')
        expect(json_response).to have_key('html')
      end
    end
  end

  describe '#labels' do
    context 'as html' do
      before do
        go(:labels, format: 'html')
      end

      it 'redirects to milestone#show' do
        expect(response).to redirect_to(milestone_path)
      end
    end

    context 'as json' do
      before do
        go(:labels, format: 'json')
      end

      it 'renders the labels tab template to a string' do
        expect(response).to render_template('shared/milestones/_labels_tab')
        expect(json_response).to have_key('html')
      end
    end
  end
end
