# frozen_string_literal: true

RSpec.shared_examples 'assigns build to package' do
  context 'with build info' do
    let(:job) { create(:ci_build, user: user) }
    let(:params) { super().merge(build: job) }

    it 'assigns the pipeline to the package' do
      package = subject

      expect(package.original_build_info).to be_present
      expect(package.original_build_info.pipeline).to eq job.pipeline
    end
  end
end

RSpec.shared_examples 'assigns the package creator' do
  it 'assigns the package creator' do
    subject

    expect(package.creator).to eq user
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
      expect(json_response.map { |package| package['id'] }).to contain_exactly(package1.id, package2.id)
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
      expect(json_response.map { |package| package['id'] }).to contain_exactly(package1.id, package2.id, package3.id)
    end
  end
end

RSpec.shared_examples 'package sorting' do |order_by|
  subject { get api(url), params: { sort: sort, order_by: order_by } }

  context "sorting by #{order_by}" do
    context 'ascending order' do
      let(:sort) { 'asc' }

      it 'returns the sorted packages' do
        subject

        expect(json_response.map { |package| package['id'] }).to eq(packages.map(&:id))
      end
    end

    context 'descending order' do
      let(:sort) { 'desc' }

      it 'returns the sorted packages' do
        subject

        expect(json_response.map { |package| package['id'] }).to eq(packages.reverse.map(&:id))
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

RSpec.shared_examples 'background upload schedules a file migration' do
  context 'background upload enabled' do
    before do
      stub_package_file_object_storage(background_upload: true)
    end

    it 'schedules migration of file to object storage' do
      expect(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async).with('Packages::PackageFileUploader', 'Packages::PackageFile', :file, kind_of(Numeric))

      subject
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

  Packages::Package.package_types.keys.each do |package_type|
    context "for package type #{package_type}" do
      let(:url) { is_project ? package_filter_url(:type, package_type) : group_filter_url(:type, package_type) }

      subject { get api(url, user) }

      it "returns #{package_type} packages" do
        subject

        expect(json_response.length).to eq(1)
        expect(json_response.map { |package| package['package_type'] }).to contain_exactly(package_type)
      end
    end
  end
end

RSpec.shared_examples 'package workhorse uploads' do
  context 'without a workhorse header' do
    let(:workhorse_token) { JWT.encode({ 'iss' => 'invalid header' }, Gitlab::Workhorse.secret, 'HS256') }

    it_behaves_like 'returning response status', :forbidden

    it 'logs an error' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).once

      subject
    end
  end
end
