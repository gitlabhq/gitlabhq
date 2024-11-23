# frozen_string_literal: true

RSpec.shared_examples 'assigns build to package' do
  context 'with build info' do
    let(:job) { create(:ci_build, user: user, project: project) }
    let(:params) { super().merge(build: job) }

    it 'assigns the pipeline to the package' do
      package = subject

      expect(package.last_build_info).to be_present
      expect(package.last_build_info.pipeline).to eq job.pipeline
    end
  end
end

RSpec.shared_examples 'assigns build to package file' do
  context 'with build info' do
    let(:job) { create(:ci_build, user: user) }
    let(:params) { super().merge(build: job) }

    it 'assigns the pipeline to the package' do
      package_file = subject

      expect(package_file.package_file_build_infos).to be_present
      expect(package_file.pipelines.first).to eq job.pipeline
    end

    it 'creates a new PackageFileBuildInfo record' do
      expect { subject }.to change { Packages::PackageFileBuildInfo.count }.by(1)
    end
  end
end

RSpec.shared_examples 'assigns the package creator' do
  it 'assigns the package creator' do
    subject

    expect(package.creator).to eq user
  end
end

RSpec.shared_examples 'assigns status to package' do
  context 'with status param' do
    let_it_be(:status) { 'hidden' }

    let(:params) { super().merge(status: status) }

    it 'assigns the status to the package' do
      package = subject

      expect(package.status).to eq(status)
    end
  end
end

RSpec.shared_examples 'returns packages' do |container_type, user_type|
  context "for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it 'returns success response' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns a valid response schema' do
      subject

      expect(response).to match_response_schema(package_schema)
    end

    it 'returns two packages' do
      subject

      expect(json_response.length).to eq(2)
      expect(json_response.pluck('id')).to contain_exactly(package1.id, package2.id)
    end
  end
end

RSpec.shared_examples 'returns package' do |container_type, user_type|
  context "for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it 'returns success response' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns a valid response schema' do
      subject

      expect(response).to match_response_schema(single_package_schema)
    end
  end
end

RSpec.shared_examples 'returns packages with subgroups' do |container_type, user_type|
  context "with subgroups for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it 'returns success response' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns a valid response schema' do
      subject

      expect(response).to match_response_schema(package_schema)
    end

    it 'returns three packages' do
      subject

      expect(json_response.length).to eq(3)
      expect(json_response.pluck('id')).to contain_exactly(package1.id, package2.id, package3.id)
    end
  end
end

RSpec.shared_examples 'package sorting' do |order_by|
  subject { get api(url), params: { sort: sort, order_by: order_by } }

  let(:package_ids_desc) { packages.reverse.map(&:id) }

  context "sorting by #{order_by}" do
    context 'ascending order' do
      let(:sort) { 'asc' }

      it 'returns the sorted packages' do
        subject

        expect(json_response.pluck('id')).to eq(packages.map(&:id))
      end
    end

    context 'descending order' do
      let(:sort) { 'desc' }

      it 'returns the sorted packages' do
        subject

        expect(json_response.pluck('id')).to eq(package_ids_desc)
      end
    end
  end
end

RSpec.shared_examples 'rejects packages access' do |container_type, user_type, status|
  context "for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'returns paginated packages' do
  let(:per_page) { 2 }

  context 'when viewing the first page' do
    let(:page) { 1 }

    it 'returns first 2 packages' do
      get api(url, user), params: { page: page, per_page: per_page }

      expect_paginated_array_response([package1.id, package2.id])
    end
  end

  context 'when viewing the second page' do
    let(:page) { 2 }

    it 'returns first 2 packages' do
      get api(url, user), params: { page: page, per_page: per_page }

      expect_paginated_array_response([package3.id, package4.id])
    end
  end
end

RSpec.shared_context 'package filter context' do
  def package_filter_url(filter, param)
    "/projects/#{project.id}/packages?package_#{filter}=#{param}"
  end

  def group_filter_url(filter, param)
    "/groups/#{group.id}/packages?package_#{filter}=#{param}"
  end
end

RSpec.shared_examples 'filters on each package_type' do |is_project: false|
  include_context 'package filter context'

  let_it_be(:package1) { create(:conan_package, project: project) }
  let_it_be(:package2) { create(:maven_package, project: project) }
  let_it_be(:package3) { create(:npm_package, project: project) }
  let_it_be(:package4) { create(:nuget_package, project: project) }
  let_it_be(:package5) { create(:pypi_package, project: project) }
  let_it_be(:package6) { create(:composer_package, project: project) }
  let_it_be(:package7) { create(:generic_package, project: project) }
  let_it_be(:package8) { create(:golang_package, project: project) }
  let_it_be(:package9) { create(:debian_package, project: project) }
  let_it_be(:package10) { create(:rubygems_package, project: project) }
  let_it_be(:package11) { create(:helm_package, project: project) }
  let_it_be(:package12) { create(:terraform_module_package, project: project) }
  let_it_be(:package13) { create(:rpm_package, project: project) }
  let_it_be(:package14) { create(:ml_model_package, project: project) }

  Packages::Package.package_types.keys.each do |package_type|
    context "for package type #{package_type}" do
      let(:url) { is_project ? package_filter_url(:type, package_type) : group_filter_url(:type, package_type) }

      subject { get api(url, user) }

      it "returns #{package_type} packages" do
        subject

        expect(json_response.length).to eq(1)
        expect(json_response.pluck('package_type')).to contain_exactly(package_type)
      end
    end
  end
end

RSpec.shared_examples 'package workhorse uploads' do
  context 'without a workhorse header' do
    let(:workhorse_token) { JWT.encode({ 'iss' => 'invalid header' }, Gitlab::Workhorse.secret, 'HS256') }

    it_behaves_like 'returning response status', :forbidden

    it 'logs an error' do
      allow(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(JWT::DecodeError)

      subject
    end
  end
end

RSpec.shared_examples 'with versionless packages' do
  context 'with versionless package' do
    let!(:versionless_package) { create(:maven_package, project: project, version: nil) }

    shared_examples 'not including the package' do
      it 'does not return the package' do
        subject

        expect(json_response.pluck('id')).not_to include(versionless_package.id)
      end
    end

    it_behaves_like 'not including the package'

    context 'with include_versionless param' do
      context 'with true include_versionless param' do
        [true, 'true', 1, '1'].each do |param|
          context "for param #{param}" do
            let(:params) { super().merge(include_versionless: param) }

            it 'returns the package' do
              subject

              expect(json_response.pluck('id')).to include(versionless_package.id)
            end
          end
        end
      end

      context 'with falsy include_versionless param' do
        [false, '', nil, 'false', 0, '0'].each do |param|
          context "for param #{param}" do
            let(:params) { super().merge(include_versionless: param) }

            it_behaves_like 'not including the package'
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'with status param' do
  context 'hidden packages' do
    let!(:hidden_package) { create(:maven_package, :hidden, project: project) }

    shared_examples 'not including the hidden package' do
      it 'does not return the package' do
        subject

        expect(json_response.pluck('id')).not_to include(hidden_package.id)
      end
    end

    context 'no status param' do
      it_behaves_like 'not including the hidden package'
    end

    context 'with hidden status param' do
      let(:params) { super().merge(status: 'hidden') }

      it 'returns the package' do
        subject

        expect(json_response.pluck('id')).to include(hidden_package.id)
      end
    end
  end

  context 'bad status param' do
    let(:params) { super().merge(status: 'invalid') }

    it 'returns the package' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
