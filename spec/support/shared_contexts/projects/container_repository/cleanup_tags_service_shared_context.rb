# frozen_string_literal: true

RSpec.shared_context 'for a cleanup tags service' do
  def expected_service_response(status: :success, deleted: [], original_size: tags.size)
    {
      status: status,
      deleted: deleted,
      original_size: original_size,
      before_delete_size: deleted&.size
    }.compact.merge(deleted_size: deleted&.size)
  end

  def expect_delete(tags, container_expiration_policy: nil)
    service = instance_double('Projects::ContainerRepository::DeleteTagsService')

    expect(Projects::ContainerRepository::DeleteTagsService)
      .to receive(:new)
      .with(repository.project, user, tags: tags, container_expiration_policy: container_expiration_policy)
      .and_return(service)

    expect(service).to receive(:execute)
                   .with(repository) { { status: :success, deleted: tags } }
  end

  def expect_no_caching
    expect(::Gitlab::Redis::Cache).not_to receive(:with)
  end
end
