# frozen_string_literal: true

RSpec.shared_examples 'milestone tabs' do
  def go(path, extra_params = {})
    get path, params: request_params.merge(extra_params)
  end

  describe '#issues' do
    context 'as html' do
      before do
        go(:issues, format: 'html')
      end

      it 'redirects to milestone#show' do
        expect(response).to redirect_to(milestone_path)
      end
    end

    context 'as json' do
      it 'renders the issues tab template to a string' do
        go(:issues, format: 'json')

        expect(response).to render_template('shared/milestones/_issues_tab')
        expect(json_response).to have_key('html')
      end
    end
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
