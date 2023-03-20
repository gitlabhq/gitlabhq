# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroySecureFileService, feature_category: :continuous_integration do
  let_it_be(:maintainer_user) { create(:user) }
  let_it_be(:developer_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:secure_file) { create(:ci_secure_file, project: project) }
  let_it_be(:project_member) { create(:project_member, :maintainer, user: maintainer_user, project: project) }
  let_it_be(:project_member2) { create(:project_member, :developer, user: developer_user, project: project) }

  subject { described_class.new(project, user).execute(secure_file) }

  context 'user is a maintainer' do
    let(:user) { maintainer_user }

    it 'destroys the secure file' do
      subject

      expect { secure_file.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'user is a developer' do
    let(:user) { developer_user }

    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
