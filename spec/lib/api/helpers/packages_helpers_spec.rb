# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PackagesHelpers do
  let_it_be(:helper) { Class.new.include(described_class).new }
  let_it_be(:project) { create(:project) }

  describe 'authorize_packages_access!' do
    subject { helper.authorize_packages_access!(project) }

    it 'authorizes packages access' do
      expect(helper).to receive(:require_packages_enabled!)
      expect(helper).to receive(:authorize_read_package!).with(project)

      expect(subject).to eq nil
    end
  end

  %i[read_package create_package destroy_package].each do |action|
    describe "authorize_#{action}!" do
      subject { helper.send("authorize_#{action}!", project) }

      it 'calls authorize!' do
        expect(helper).to receive(:authorize!).with(action, project)

        expect(subject).to eq nil
      end
    end
  end

  describe 'require_packages_enabled!' do
    let(:packages_enabled) { true }

    subject { helper.require_packages_enabled! }

    before do
      allow(::Gitlab.config.packages).to receive(:enabled).and_return(packages_enabled)
    end

    context 'with packages enabled' do
      it "doesn't call not_found!" do
        expect(helper).to receive(:not_found!).never

        expect(subject).to eq nil
      end
    end

    context 'with package disabled' do
      let(:packages_enabled) { false }

      it 'calls not_found!' do
        expect(helper).to receive(:not_found!).once

        subject
      end
    end
  end

  describe '#authorize_workhorse!' do
    let_it_be(:headers) { {} }

    subject { helper.authorize_workhorse!(subject: project) }

    before do
      allow(helper).to receive(:headers).and_return(headers)
    end

    it 'authorizes workhorse' do
      expect(helper).to receive(:authorize_upload!).with(project)
      expect(helper).to receive(:status).with(200)
      expect(helper).to receive(:content_type).with(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(Gitlab::Workhorse).to receive(:verify_api_request!).with(headers)
      expect(::Packages::PackageFileUploader).to receive(:workhorse_authorize).with(has_length: true)

      expect(subject).to eq nil
    end

    context 'without length' do
      subject { helper.authorize_workhorse!(subject: project, has_length: false) }

      it 'authorizes workhorse' do
        expect(helper).to receive(:authorize_upload!).with(project)
        expect(helper).to receive(:status).with(200)
        expect(helper).to receive(:content_type).with(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(Gitlab::Workhorse).to receive(:verify_api_request!).with(headers)
        expect(::Packages::PackageFileUploader).to receive(:workhorse_authorize).with(has_length: false, maximum_size: ::API::Helpers::PackagesHelpers::MAX_PACKAGE_FILE_SIZE)

        expect(subject).to eq nil
      end
    end
  end

  describe '#authorize_upload!' do
    subject { helper.authorize_upload!(project) }

    it 'authorizes the upload' do
      expect(helper).to receive(:authorize_create_package!).with(project)
      expect(helper).to receive(:require_gitlab_workhorse!)

      expect(subject).to eq nil
    end
  end
end
