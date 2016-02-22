require 'spec_helper'
require 'email_spec'
require 'mailers/shared/notify'

describe Notify do
  include EmailSpec::Matchers

  include_context 'gitlab email notification'

  describe 'build notification email' do
    let(:build) { create(:ci_build) }
    let(:project) { build.project }

    shared_examples 'build email' do
      it 'contains name of project' do
        is_expected.to have_body_text build.project_name
      end

      it 'contains link to project' do
        is_expected.to have_body_text namespace_project_path(project.namespace, project)
      end
    end

    shared_examples 'an email with X-GitLab headers containing build details' do
      it 'has X-GitLab-Build* headers' do
        is_expected.to have_header 'X-GitLab-Build-Id', /#{build.id}/
        is_expected.to have_header 'X-GitLab-Build-Ref', /#{build.ref}/
      end
    end

    describe 'build success' do
      subject { Notify.build_success_email(build.id, 'wow@example.com') }
      before { build.success }

      it_behaves_like 'build email'
      it_behaves_like 'an email with X-GitLab headers containing build details'
      it_behaves_like 'an email with X-GitLab headers containing project details'

      it 'has header indicating build status' do
        is_expected.to have_header 'X-GitLab-Build-Status', 'success'
      end

      it 'has the correct subject' do
        is_expected.to have_subject /Build success for/
      end
    end

    describe 'build fail' do
      subject { Notify.build_fail_email(build.id, 'wow@example.com') }
      before { build.drop }

      it_behaves_like 'build email'
      it_behaves_like 'an email with X-GitLab headers containing build details'
      it_behaves_like 'an email with X-GitLab headers containing project details'

      it 'has header indicating build status' do
        is_expected.to have_header 'X-GitLab-Build-Status', 'failed'
      end

      it 'has the correct subject' do
        is_expected.to have_subject /Build failed for/
      end
    end
  end
end
