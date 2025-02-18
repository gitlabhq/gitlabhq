# frozen_string_literal: true

RSpec.shared_examples 'Debian distributions GET request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  it "returns #{status}#{and_body}" do
    subject

    expect(response).to have_gitlab_http_status(status)

    unless body.nil?
      expect(response.body).to match(body)
    end
  end
end

RSpec.shared_examples 'Debian distributions PUT request' do |status, body|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :success
    it 'updates distribution', :aggregate_failures do
      expect(::Packages::Debian::UpdateDistributionService).to receive(:new).with(distribution, api_params.except(:codename)).and_call_original

      expect { subject }
          .to not_change { Packages::Debian::GroupDistribution.all.count + Packages::Debian::ProjectDistribution.all.count }
          .and not_change { Packages::Debian::GroupComponent.all.count + Packages::Debian::ProjectComponent.all.count }
          .and not_change { Packages::Debian::GroupArchitecture.all.count + Packages::Debian::ProjectArchitecture.all.count }

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/json')

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian distributions DELETE request' do |status, body|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :success
    it 'updates distribution', :aggregate_failures do
      expect { subject }
          .to change { Packages::Debian::GroupDistribution.all.count + Packages::Debian::ProjectDistribution.all.count }.by(-1)
          .and change { Packages::Debian::GroupComponent.all.count + Packages::Debian::ProjectComponent.all.count }.by(-1)
          .and change { Packages::Debian::GroupArchitecture.all.count + Packages::Debian::ProjectArchitecture.all.count }.by(-2)

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/json')

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian distributions POST request' do |status, body|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :created
    it 'creates distribution', :aggregate_failures do
      expect(::Packages::Debian::CreateDistributionService).to receive(:new).with(container, user, api_params).and_call_original

      expect { subject }
          .to change { Packages::Debian::GroupDistribution.all.count + Packages::Debian::ProjectDistribution.all.count }.by(1)
          .and change { Packages::Debian::GroupComponent.all.count + Packages::Debian::ProjectComponent.all.count }.by(1)
          .and change { Packages::Debian::GroupArchitecture.all.count + Packages::Debian::ProjectArchitecture.all.count }.by(2)

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/json')

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian distributions read endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_type, :auth_method, :expected_status, :expected_body) do
      :public  | :guest         | :private_token | success_status | success_body
      :public  | :not_a_member  | :private_token | success_status | success_body
      :public  | :anonymous     | :private_token | success_status | success_body
      :public  | :invalid_token | :private_token | :unauthorized  | nil
      :private | :developer     | :private_token | success_status | success_body
      :private | :developer     | :basic         | :not_found     | nil
      :private | :guest         | :private_token | success_status | success_body
      :private | :not_a_member  | :private_token | :not_found     | nil
      :private | :anonymous     | :private_token | :not_found     | nil
      :private | :invalid_token | :private_token | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_type], params[:auth_method] do
        it_behaves_like "Debian distributions #{desired_behavior} request", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id', :not_found, :private_token
end

RSpec.shared_examples 'Debian distributions write endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_type, :auth_method, :expected_status, :expected_body) do
      :public  | :developer     | :private_token | success_status | success_body
      :public  | :developer     | :basic         | :unauthorized  | nil
      :public  | :guest         | :private_token | :forbidden     | nil
      :public  | :not_a_member  | :private_token | :forbidden     | nil
      :public  | :anonymous     | :private_token | :unauthorized  | nil
      :public  | :invalid_token | :private_token | :unauthorized  | nil
      :private | :developer     | :private_token | success_status | success_body
      :private | :guest         | :private_token | :forbidden     | nil
      :private | :not_a_member  | :private_token | :not_found     | nil
      :private | :anonymous     | :private_token | :not_found     | nil
      :private | :invalid_token | :private_token | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_type], params[:auth_method] do
        it_behaves_like "Debian distributions #{desired_behavior} request", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id', :not_found, :private_token
end

RSpec.shared_examples 'Debian distributions maintainer write endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_type, :auth_method, :expected_status, :expected_body) do
      :public  | :maintainer    | :private_token | success_status | success_body
      :public  | :maintainer    | :basic         | :unauthorized  | nil
      :public  | :developer     | :private_token | :forbidden     | nil
      :public  | :not_a_member  | :private_token | :forbidden     | nil
      :public  | :anonymous     | :private_token | :unauthorized  | nil
      :public  | :invalid_token | :private_token | :unauthorized  | nil
      :private | :maintainer    | :private_token | success_status | success_body
      :private | :developer     | :private_token | :forbidden     | nil
      :private | :not_a_member  | :private_token | :not_found     | nil
      :private | :anonymous     | :private_token | :not_found     | nil
      :private | :invalid_token | :private_token | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_type], params[:auth_method] do
        it_behaves_like "Debian distributions #{desired_behavior} request", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id', :not_found, :private_token
end
