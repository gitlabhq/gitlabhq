# frozen_string_literal: true

RSpec.shared_examples 'Web hook destroyer' do
  it 'displays a message about synchronous delete', :aggregate_failures do
    expect_next_instance_of(WebHooks::DestroyService) do |instance|
      expect(instance).to receive(:execute).with(anything).and_call_original
    end

    delete :destroy, params: params

    expect(response).to have_gitlab_http_status(:found)
    expect(flash[:notice]).to eq('Webhook was deleted')
  end

  it 'displays a message about async delete', :aggregate_failures do
    expect_next_instance_of(WebHooks::DestroyService) do |instance|
      expect(instance).to receive(:execute).with(anything).and_return({ status: :success, async: true })
    end

    delete :destroy, params: params

    expect(response).to have_gitlab_http_status(:found)
    expect(flash[:notice]).to eq('Webhook was scheduled for deletion')
  end

  it 'displays an error if deletion failed', :aggregate_failures do
    expect_next_instance_of(WebHooks::DestroyService) do |instance|
      expect(instance).to receive(:execute).with(anything).and_return({ status: :error, async: true, message: "failed" })
    end

    delete :destroy, params: params

    expect(response).to have_gitlab_http_status(:found)
    expect(flash[:alert]).to eq("failed")
  end
end
