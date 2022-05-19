# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyPolicy do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  subject { described_class.new(user, project.container_expiration_policy) }

  where(:user_type, :allowed_to_destroy_container_image) do
    :anonymous  | false
    :guest      | false
    :developer  | false
    :maintainer | true
  end

  with_them do
    context "for user type #{params[:user_type]}" do
      before do
        project.public_send("add_#{user_type}", user) unless user_type == :anonymous
      end

      if params[:allowed_to_destroy_container_image]
        it { is_expected.to be_allowed(:admin_container_image) }
      else
        it { is_expected.not_to be_allowed(:admin_container_image) }
      end
    end
  end
end
