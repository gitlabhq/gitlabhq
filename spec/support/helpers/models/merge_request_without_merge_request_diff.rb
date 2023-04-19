# frozen_string_literal: true

class MergeRequestWithoutMergeRequestDiff < ::MergeRequest # rubocop:disable Gitlab/NamespacedClass
  self.inheritance_column = :_type_disabled

  def ensure_merge_request_diff; end
end
