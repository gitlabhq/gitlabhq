/* global BoardService */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import '~/labels_select';
import LabelsSelect from 'ee/boards/components/labels_select.vue';
import IssuableContext from '~/issuable_context';

let vm;

function selectedText() {
  return vm.$el.querySelector('.value').innerText.trim();
}

function activeDropdownItem(index) {
  const items = document.querySelectorAll('.is-active');
  if (!items[index]) return '';
  return items[index].innerText.trim();
}

const label = {
  id: '1',
  title: 'Testing',
  color: 'red',
  description: 'testing;',
};

const label2 = {
  id: 2,
  title: 'Still Testing',
  color: 'red',
  description: 'testing;',
};

describe('LabelsSelect', () => {
  let mock;

  beforeEach((done) => {
    setFixtures('<div class="test-container"></div>');

    mock = new MockAdapter(axios);
    mock.onGet('/some/path').reply(200, [
      label,
      label2,
    ]);

    // eslint-disable-next-line no-new
    new IssuableContext();

    const propsData = {
      board: {
        labels: [],
      },
      canEdit: true,
      labelsPath: '/some/path',
    };

    const Component = Vue.extend(LabelsSelect);
    vm = new Component({
      propsData,
    }).$mount('.test-container');

    Vue.nextTick(done);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('canEdit', () => {
    it('hides Edit button', (done) => {
      vm.canEdit = false;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeFalsy();
        done();
      });
    });

    it('shows Edit button if true', (done) => {
      vm.canEdit = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeTruthy();
        done();
      });
    });
  });

  describe('selected', () => {
    it('shows Any Label', () => {
      expect(selectedText()).toContain('Any Label');
    });

    it('shows single label', (done) => {
      vm.board.labels = [label];
      Vue.nextTick(() => {
        expect(selectedText()).toContain(label.title);
        done();
      });
    });

    it('shows multiple labels', (done) => {
      vm.board.labels = [label, label2];
      Vue.nextTick(() => {
        expect(selectedText()).toContain(label.title);
        expect(selectedText()).toContain(label2.title);
        done();
      });
    });
  });

  describe('clicking dropdown items', () => {
    it('sets No labels', (done) => {
      vm.board.labels = [label];
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        vm.$el.querySelectorAll('li a')[0].click();
      });

      setTimeout(() => {
        expect(activeDropdownItem(0)).toEqual('Any Label');
        expect(vm.board.labels).toEqual([]);
        done();
      });
    });

    it('sets value', (done) => {
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        vm.$el.querySelectorAll('li a')[1].click();
      });

      setTimeout(() => {
        expect(activeDropdownItem(0)).toEqual(label.title);
        expect(vm.board.labels[0].title).toEqual(label.title);
        done();
      });
    });
  });
});
