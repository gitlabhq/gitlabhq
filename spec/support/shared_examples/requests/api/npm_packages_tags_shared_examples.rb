# frozen_string_literal: true

RSpec.shared_examples 'accept package tags request' do |status:|
  using RSpec::Parameterized::TableSyntax
  include_context 'dependency proxy helpers context'

  before do
    allow_fetch_application_setting(attribute: "npm_package_requests_forwarding", return_value: false)
    allow_fetch_cascade_application_setting(attribute: "npm_package_requests_forwarding", return_value: false)
  end

  context 'with valid package name' do
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', status
    it_behaves_like 'track event', :list_tags

    it 'returns a valid json response' do
      subject

      expect(response.media_type).to eq('application/json')
      expect(json_response).to be_a(Hash)
    end

    it 'returns two package tags' do
      subject

      expect(json_response).to match_schema('public_api/v4/packages/npm_package_tags')
      expect(json_response.length).to eq(3) # two tags + latest (auto added)
      expect(json_response[package_tag1.name]).to eq(package.version)
      expect(json_response[package_tag2.name]).to eq(package.version)
      expect(json_response['latest']).to eq(package.version)
    end
  end

  context 'with invalid package name' do
    where(:package_name, :status) do
      '%20' | :bad_request
      nil   | :not_found
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end
end

RSpec.shared_examples 'accept create package tag request' do |user_type|
  using RSpec::Parameterized::TableSyntax

  context 'with valid package name' do
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', :no_content
    it_behaves_like 'track event', :create_tag

    it 'creates the package tag' do
      expect { subject }.to change { Packages::Tag.count }.by(1)

      last_tag = Packages::Tag.last
      expect(last_tag.name).to eq(tag_name)
      expect(last_tag.package).to eq(package)
    end

    it 'returns a valid response' do
      subject

      expect(response.body).to be_empty
    end

    context 'with already existing tag' do
      let_it_be(:package2) { create(:npm_package, project: project, name: package.name, version: '5.5.55') }
      let_it_be(:tag) { create(:packages_tag, package: package2, name: tag_name) }

      it_behaves_like 'returning response status', :no_content

      it 'reuses existing tag' do
        expect(package.tags).to be_empty
        expect(package2.tags).to eq([tag])
        expect { subject }.to not_change { Packages::Tag.count }
        expect(package.reload.tags).to eq([tag])
        expect(package2.reload.tags).to be_empty
      end

      it 'returns a valid response' do
        subject

        expect(response.body).to be_empty
      end
    end
  end

  context 'with invalid package name' do
    where(:package_name, :status) do
      'unknown' | :not_found
      ''        | :not_found
      '%20'     | :bad_request
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end

  context 'with invalid tag name' do
    where(:tag_name, :status) do
      ''    | :not_found
      '%20' | :bad_request
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end

  context 'with invalid version' do
    where(:version, :status) do
      ' '   | :bad_request
      ''    | :bad_request
      nil   | :bad_request
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end
end

RSpec.shared_examples 'accept delete package tag request' do |user_type|
  using RSpec::Parameterized::TableSyntax

  context 'with valid package name' do
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', :no_content
    it_behaves_like 'track event', :delete_tag

    it 'returns a valid response' do
      subject

      expect(response.body).to be_empty
    end

    it 'destroy the package tag' do
      expect(package.tags).to eq([package_tag])
      expect { subject }.to change { Packages::Tag.count }.by(-1)
      expect(package.reload.tags).to be_empty
    end

    context 'with tag from other package' do
      let(:package2) { create(:npm_package, project: project) }
      let(:package_tag) { create(:packages_tag, package: package2) }

      it_behaves_like 'returning response status', :not_found
    end
  end

  context 'with invalid package name' do
    where(:package_name, :status) do
      'unknown' | :not_found
      ''        | :not_found
      '%20'     | :bad_request
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end

  context 'with invalid tag name' do
    where(:tag_name, :status) do
      'unknown' | :not_found
      ''        | :not_found
      '%20'     | :bad_request
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end
end

RSpec.shared_examples 'track event' do |event_name|
  let(:event_user) do
    if auth == :deploy_token
      deploy_token
    elsif user_role
      user
    end
  end

  let(:snowplow_gitlab_standard_context) do
    { project: project, namespace: project.namespace, property: 'i_package_npm_user' }.tap do |context|
      context[:user] = event_user if event_user
    end
  end

  it_behaves_like 'a package tracking event', described_class.name, event_name.to_s
end
