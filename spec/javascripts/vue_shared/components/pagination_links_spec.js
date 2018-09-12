import Vue from 'vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { s__ } from '~/locale';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Pagination links component', () => {
  const paginationLinksComponent = Vue.extend(PaginationLinks);
  const change = page => page;
  const pageInfo = {
    page: 3,
    perPage: 5,
    total: 30,
  };
  const translations = {
    firstText: s__('Pagination|« First'),
    prevText: s__('Pagination|Prev'),
    nextText: s__('Pagination|Next'),
    lastText: s__('Pagination|Last »'),
  };

  let paginationLinks;
  let glPagination;
  let destinationComponent;

  beforeEach(() => {
    paginationLinks = mountComponent(
      paginationLinksComponent,
      {
        change,
        pageInfo,
      },
    );
    [glPagination] = paginationLinks.$children;
    [destinationComponent] = glPagination.$children;
  });

  afterEach(() => {
    paginationLinks.$destroy();
  });

  it('should provide translated text to GitLab UI pagination', () => {
    Object.entries(translations).forEach(entry =>
      expect(
        destinationComponent[entry[0]],
      ).toBe(entry[1]),
    );
  });

  it('should pass change to GitLab UI pagination', () => {
    expect(
      Object.is(glPagination.change, change),
    ).toBe(true);
  });

  it('should pass page from pageInfo to GitLab UI pagination', () => {
    expect(
      destinationComponent.value,
    ).toBe(pageInfo.page);
  });

  it('should pass per page from pageInfo to GitLab UI pagination', () => {
    expect(
      destinationComponent.perPage,
    ).toBe(pageInfo.perPage);
  });

  it('should pass total items from pageInfo to GitLab UI pagination', () => {
    expect(
      destinationComponent.totalRows,
    ).toBe(pageInfo.total);
  });
});
