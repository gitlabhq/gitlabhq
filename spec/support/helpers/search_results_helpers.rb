# frozen_string_literal: true

module SearchResultHelpers
  # @param target [Symbol] search target, e.g. "merge_requests", "blobs"
  def expect_search_results(users, target, expected_count: nil, expected_objects: nil)
    # TODO: https://gitlab.com/gitlab-org/gitlab/issues/32645
    return if expected_count && expected_count > 0

    users = Array(users)
    target = target.to_s

    users.each do |user|
      user_name = user&.name || 'anonymous user'
      results = yield(user)
      objects = results.objects(target)

      if expected_count
        actual_count = results.public_send("#{target}_count")

        expect(actual_count).to eq(expected_count), "expected count to be #{expected_count} for #{user_name}, got #{actual_count}"
      end

      if expected_objects
        if expected_objects.empty?
          expect(objects.empty?).to eq(true)
        else
          expect(objects).to contain_exactly(*expected_objects)
        end
      end
    end
  end
end
