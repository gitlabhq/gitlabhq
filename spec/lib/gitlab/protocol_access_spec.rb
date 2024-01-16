# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::ProtocolAccess, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:p1) { create(:project, :repository, namespace: group) }

  describe ".allowed?" do
    where(:protocol, :project, :admin_setting, :namespace_setting, :expected_result) do
      "web"  | nil       | nil    | nil    | true
      "ssh"  | nil       | nil    | nil    | true
      "http" | nil       | nil    | nil    | true
      "ssh"  | nil       | ""     | nil    | true
      "http" | nil       | ""     | nil    | true
      "ssh"  | nil       | "ssh"  | nil    | true
      "http" | nil       | "http" | nil    | true
      "ssh"  | nil       | "http" | nil    | false
      "http" | nil       | "ssh"  | nil    | false
      "ssh"  | ref(:p1)  | nil    | "all"  | true
      "http" | ref(:p1)  | nil    | "all"  | true
      "ssh"  | ref(:p1)  | nil    | "ssh"  | true
      "http" | ref(:p1)  | nil    | "http" | true
      "ssh"  | ref(:p1)  | nil    | "http" | false
      "http" | ref(:p1)  | nil    | "ssh"  | false
      "ssh"  | ref(:p1)  | ""     | "all"  | true
      "http" | ref(:p1)  | ""     | "all"  | true
      "ssh"  | ref(:p1)  | "ssh"  | "ssh"  | true
      "http" | ref(:p1)  | "http" | "http" | true
    end

    with_them do
      subject { described_class.allowed?(protocol, project: project) }

      before do
        allow(Gitlab::CurrentSettings).to receive(:enabled_git_access_protocol).and_return(admin_setting)

        if project.present?
          project.root_namespace.namespace_settings.update!(enabled_git_access_protocol: namespace_setting)
        end
      end

      it do
        is_expected.to be(expected_result)
      end
    end
  end
end
