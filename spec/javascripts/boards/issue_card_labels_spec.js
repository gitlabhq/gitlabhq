import Vue from 'vue';
import labelsComponent from '~/boards/components/issue_card_labels';
import eventHub from '~/boards/eventhub';
import '~/boards/stores/boards_store';

const propData = {
  labels: [{
    color: 'rgb(0, 0, 0)',
    textColor: 'rgb(255, 255, 255)',
    description: '',
    id: 1,
    title: 'Frontend',
  }, {
    color: 'rgb(255, 255, 255)',
    textColor: 'rgb(0, 0, 0)',
    description: '',
    id: 2,
    title: 'Community Contribution',
  }],
  list: {
    color: 'rgb(0, 0, 0)',
    id: 3,
    title: 'bug',
  },
  updateFilters: true,
};

const createComponent = (propsData) => {
  const Component = Vue.extend(labelsComponent);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('IssueCardLabels', () => {
  describe('props', () => {
    const props = labelsComponent.props;

    it('should have labels prop', () => {
      const { labels } = props;
      const LabelsClass = labels.type;

      expect(labels).toBeDefined();
      expect(new LabelsClass() instanceof Array).toBeTruthy();
      expect(labels.required).toBeTruthy();
    });

    it('should have list prop', () => {
      const { list } = props;

      expect(list).toBeDefined();
      expect(list instanceof Object).toBeTruthy();
      expect(list.required).toBeFalsy();
    });

    it('should have updateFilters prop', () => {
      const { updateFilters } = props;
      const UpdateFiltersClass = updateFilters.type;

      expect(updateFilters).toBeDefined();
      expect(new UpdateFiltersClass() instanceof Boolean).toBeTruthy();
      expect(updateFilters.required).toBeFalsy();
      expect(updateFilters.default).toBeFalsy();
    });
  });

  describe('methods', () => {
    describe('showLabel', () => {
      it('should return true if there is no list', () => {
        const data = Object.assign({}, propData);
        data.list = null;
        const vm = createComponent(data);

        expect(vm.showLabel()).toEqual(true);
      });

      it('should return true if there is a list and no list.label', () => {
        const vm = createComponent(propData);

        expect(vm.showLabel()).toEqual(true);
      });

      it('should return true if list.label.id does not match label.id', () => {
        const data = Object.assign({}, propData);
        data.list.label = {
          id: 100,
        };
        const vm = createComponent(data);

        const showLabel = vm.showLabel({
          id: 1,
        });

        expect(showLabel).toEqual(true);
      });
    });

    describe('filterByLabel', () => {
      it('should not continue if there is no updateFilters set', () => {
        const data = Object.assign({}, propData);
        data.updateFilters = null;

        const spy = spyOn(gl.issueBoards.BoardsStore.filter.path, 'split').and.callThrough();
        const vm = createComponent(data);
        vm.filterByLabel({ title: 'title' }, { currentTarget: '' });

        expect(spy).not.toHaveBeenCalled();
      });

      it('should hide tooltip', () => {
        const spy = spyOn($.fn, 'tooltip').and.callFake(() => {});
        const vm = createComponent(propData);

        vm.filterByLabel({ title: 'title' }, { currentTarget: '' });
        expect(spy).toHaveBeenCalledWith('hide');
      });

      it('should add/remove label to BoardsStore filter path', () => {
        const originalPath = gl.issueBoards.BoardsStore.filter.path;
        const vm = createComponent(propData);

        const label = { title: 'special' };
        vm.filterByLabel(label, { currentTarget: '' });

        expect(gl.issueBoards.BoardsStore.filter.path).toEqual(`${originalPath}&label_name[]=${label.title}`);

        vm.filterByLabel(label, { currentTarget: '' });
        expect(gl.issueBoards.BoardsStore.filter.path).toEqual(originalPath);
      });

      it('should encode label title', () => {
        const originalPath = gl.issueBoards.BoardsStore.filter.path;
        const vm = createComponent(propData);

        const label = { title: '!@#$%^ &*()' };
        vm.filterByLabel(label, { currentTarget: '' });

        expect(gl.issueBoards.BoardsStore.filter.path).toEqual(`${originalPath}&label_name[]=${encodeURIComponent(label.title)}`);
      });

      it('should updateFiltersUrl', () => {
        spyOn(gl.issueBoards.BoardsStore, 'updateFiltersUrl').and.callFake(() => {});

        const vm = createComponent(propData);
        vm.filterByLabel({ title: 'title' }, { currentTarget: '' });

        expect(gl.issueBoards.BoardsStore.updateFiltersUrl).toHaveBeenCalled();
        expect(gl.issueBoards.BoardsStore.updateFiltersUrl.calls.count()).toEqual(1);
      });

      it('should emit updateTokens to eventHub', (done) => {
        const vm = createComponent(propData);
        spyOn(eventHub, '$emit').and.callFake((message) => {
          expect(message).toEqual('updateTokens');
          done();
        });

        vm.filterByLabel({ title: 'title' }, { currentTarget: '' });
      });
    });

    describe('labelStyle', () => {
      it('should return style object with backgroundColor and color', () => {
        const data = {
          color: '#000000',
          textColor: '#FFFFFF',
        };

        const vm = createComponent(propData);
        const style = vm.labelStyle(data);
        expect(style.backgroundColor).toEqual(data.color);
        expect(style.color).toEqual(data.textColor);
      });
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const vm = createComponent(propData);
      const el = vm.$el;
      spyOn(vm, 'filterByLabel').and.callThrough();

      expect(el.tagName).toEqual('DIV');
      expect(el.classList.contains('card-footer')).toEqual(true);

      const labels = el.querySelectorAll('button');
      expect(labels.length).toEqual(2);

      const firstLabel = labels[0];
      expect(firstLabel.getAttribute('type')).toEqual('button');
      expect(firstLabel.textContent.trim()).toEqual(propData.labels[0].title);
      expect(firstLabel.getAttribute('title')).toEqual(propData.labels[0].description);
      expect(firstLabel.style.backgroundColor).toEqual(propData.labels[0].color);
      expect(firstLabel.style.color).toEqual(propData.labels[0].textColor);

      firstLabel.click();
      expect(vm.filterByLabel).toHaveBeenCalled();
      expect(vm.filterByLabel.calls.count()).toEqual(1);
      vm.filterByLabel.calls.reset();

      const secondLabel = labels[1];
      expect(secondLabel.getAttribute('type')).toEqual('button');
      expect(secondLabel.textContent.trim()).toEqual(propData.labels[1].title);
      expect(secondLabel.getAttribute('title')).toEqual(propData.labels[1].description);
      expect(secondLabel.style.backgroundColor).toEqual(propData.labels[1].color);
      expect(secondLabel.style.color).toEqual(propData.labels[1].textColor);

      secondLabel.click();
      expect(vm.filterByLabel).toHaveBeenCalled();
      expect(vm.filterByLabel.calls.count()).toEqual(1);
    });

    it('should not display label if showLabel is false', () => {
      const data = Object.assign({}, propData);
      data.list.label = {
        id: 1,
      };
      const vm = createComponent(data);
      const el = vm.$el;

      const labels = el.querySelectorAll('button');
      expect(labels.length).toEqual(1);
    });
  });
});
