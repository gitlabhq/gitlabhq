# frozen_string_literal: true

RSpec.shared_examples 'group and projects packages resolver' do
  context 'without sort' do
    let_it_be(:npm_package) { create(:npm_package, project: project) }

    it 'returns the proper packages' do
      expect(::Packages::Package).not_to receive(:preload_pipelines)

      expect(subject).to contain_exactly(npm_package)
    end
  end

  context 'with sorting and filtering' do
    let_it_be(:conan_package) do
      create(:conan_package, name: 'bar', project: project, created_at: 1.day.ago, version: "1.0.0", status: 'default')
    end

    let_it_be(:maven_package) do
      create(:maven_package, name: 'foo', project: project, created_at: 1.hour.ago, version: "2.0.0", status: 'error')
    end

    let_it_be(:repository3) do
      create(:maven_package, name: 'baz', project: project, created_at: 1.minute.ago, version: nil)
    end

    %w[CREATED_DESC NAME_DESC VERSION_DESC TYPE_ASC].each do |order|
      context order.to_s do
        let(:args) { { sort: order } }

        it { is_expected.to eq([maven_package, conan_package]) }
      end
    end

    %w[CREATED_ASC NAME_ASC VERSION_ASC TYPE_DESC].each do |order|
      context order.to_s do
        let(:args) { { sort: order } }

        it { is_expected.to eq([conan_package, maven_package]) }
      end
    end

    context 'filter by package_name' do
      let(:args) { { package_name: 'bar', sort: 'CREATED_DESC' } }

      it { is_expected.to eq([conan_package]) }
    end

    context 'filter by package_type' do
      let(:args) { { package_type: 'conan', sort: 'CREATED_DESC' } }

      it { is_expected.to eq([conan_package]) }
    end

    context 'filter by package_version' do
      let(:args) { { package_version: '1.0.0', sort: 'CREATED_DESC' } }

      it { is_expected.to eq([conan_package]) }

      it 'includes_versionless has no effect' do
        args[:include_versionless] = true

        is_expected.to eq([conan_package])
      end
    end

    context 'filter by status' do
      let(:args) { { status: 'error', sort: 'CREATED_DESC' } }

      it { is_expected.to eq([maven_package]) }
    end

    context 'include_versionless' do
      let(:args) { { include_versionless: true, sort: 'CREATED_DESC' } }

      it { is_expected.to include(repository3) }
    end
  end
end
