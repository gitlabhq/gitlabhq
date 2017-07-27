import CloseReopenReportToggle from '~/close_reopen_report_toggle';
import DropLab from '~/droplab/drop_lab';

describe('CloseReopenReportToggle', () => {
  describe('class constructor', () => {
    const dropdownTrigger = {};
    const dropdownList = {};
    const button = {};
    let commentTypeToggle;

    beforeEach(function () {
      commentTypeToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });
    });

    it('sets .dropdownTrigger', function () {
      expect(commentTypeToggle.dropdownTrigger).toBe(dropdownTrigger);
    });

    it('sets .dropdownList', function () {
      expect(commentTypeToggle.dropdownList).toBe(dropdownList);
    });

    it('sets .button', function () {
      expect(commentTypeToggle.button).toBe(button);
    });
  });

  describe('initDroplab', () => {
    let closeReopenReportToggle;
    const dropdownList = jasmine.createSpyObj('dropdownList', ['querySelector']);
    const dropdownTrigger = {};
    const button = {};
    const reopenItem = {};
    const closeItem = {};
    const config = {};

    beforeEach(() => {
      spyOn(DropLab.prototype, 'init');
      dropdownList.querySelector.and.returnValues(reopenItem, closeItem);

      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });

      spyOn(closeReopenReportToggle, 'setConfig').and.returnValue(config);

      closeReopenReportToggle.initDroplab();
    });

    it('sets .reopenItem and .closeItem', () => {
      expect(dropdownList.querySelector).toHaveBeenCalledWith('.reopen-item');
      expect(dropdownList.querySelector).toHaveBeenCalledWith('.close-item');
      expect(closeReopenReportToggle.reopenItem).toBe(reopenItem);
      expect(closeReopenReportToggle.closeItem).toBe(closeItem);
    });

    it('sets .droplab', () => {
      expect(closeReopenReportToggle.droplab).toEqual(jasmine.any(Object));
    });

    it('calls .setConfig', () => {
      expect(closeReopenReportToggle.setConfig).toHaveBeenCalled();
    });

    it('calls droplab.init', () => {
      expect(DropLab.prototype.init).toHaveBeenCalledWith(
        dropdownTrigger,
        dropdownList,
        jasmine.any(Array),
        config,
      );
    });
  });

  describe('updateButton', () => {
    let closeReopenReportToggle;
    const dropdownList = {};
    const dropdownTrigger = {};
    const button = jasmine.createSpyObj('button', ['blur']);
    const isClosed = true;

    beforeEach(() => {
      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });

      spyOn(closeReopenReportToggle, 'toggleButtonType');

      closeReopenReportToggle.updateButton(isClosed);
    });

    it('calls .toggleButtonType', () => {
      expect(closeReopenReportToggle.toggleButtonType).toHaveBeenCalledWith(isClosed);
    });

    it('calls .button.blur', () => {
      expect(closeReopenReportToggle.button.blur).toHaveBeenCalled();
    });
  });

  describe('toggleButtonType', () => {
    let closeReopenReportToggle;
    const dropdownList = {};
    const dropdownTrigger = {};
    const button = {};
    const isClosed = true;
    const showItem = jasmine.createSpyObj('showItem', ['click']);
    const hideItem = {};
    showItem.classList = jasmine.createSpyObj('classList', ['add', 'remove']);
    hideItem.classList = jasmine.createSpyObj('classList', ['add', 'remove']);

    beforeEach(() => {
      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });

      spyOn(closeReopenReportToggle, 'getButtonTypes').and.returnValue([showItem, hideItem]);

      closeReopenReportToggle.toggleButtonType(isClosed);
    });

    it('calls .getButtonTypes', () => {
      expect(closeReopenReportToggle.getButtonTypes).toHaveBeenCalledWith(isClosed);
    });

    it('removes hide class and add selected class to showItem, opposite for hideItem', () => {
      expect(showItem.classList.remove).toHaveBeenCalledWith('hidden');
      expect(showItem.classList.add).toHaveBeenCalledWith('droplab-item-selected');
      expect(hideItem.classList.add).toHaveBeenCalledWith('hidden');
      expect(hideItem.classList.remove).toHaveBeenCalledWith('droplab-item-selected');
    });

    it('clicks the showItem', () => {
      expect(showItem.click).toHaveBeenCalled();
    });
  });

  describe('getButtonTypes', () => {
    let closeReopenReportToggle;
    const dropdownList = {};
    const dropdownTrigger = {};
    const button = {};
    const reopenItem = {};
    const closeItem = {};

    beforeEach(() => {
      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });

      closeReopenReportToggle.reopenItem = reopenItem;
      closeReopenReportToggle.closeItem = closeItem;
    });

    it('returns reopenItem, closeItem if isClosed is true', () => {
      const buttonTypes = closeReopenReportToggle.getButtonTypes(true);

      expect(buttonTypes).toEqual([reopenItem, closeItem]);
    });

    it('returns closeItem, reopenItem if isClosed is false', () => {
      const buttonTypes = closeReopenReportToggle.getButtonTypes(false);

      expect(buttonTypes).toEqual([closeItem, reopenItem]);
    });
  });

  describe('setDisable', () => {
    let closeReopenReportToggle;
    const dropdownList = {};
    const dropdownTrigger = jasmine.createSpyObj('button', ['setAttribute', 'removeAttribute']);
    const button = jasmine.createSpyObj('button', ['setAttribute', 'removeAttribute']);

    beforeEach(() => {
      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });
    });

    it('disable .button and .dropdownTrigger if shouldDisable is true', () => {
      closeReopenReportToggle.setDisable(true);

      expect(button.setAttribute).toHaveBeenCalledWith('disabled', 'true');
      expect(dropdownTrigger.setAttribute).toHaveBeenCalledWith('disabled', 'true');
    });

    it('disable .button and .dropdownTrigger if shouldDisable is undefined', () => {
      closeReopenReportToggle.setDisable();

      expect(button.setAttribute).toHaveBeenCalledWith('disabled', 'true');
      expect(dropdownTrigger.setAttribute).toHaveBeenCalledWith('disabled', 'true');
    });

    it('enable .button and .dropdownTrigger if shouldDisable is false', () => {
      closeReopenReportToggle.setDisable(false);

      expect(button.removeAttribute).toHaveBeenCalledWith('disabled');
      expect(dropdownTrigger.removeAttribute).toHaveBeenCalledWith('disabled');
    });
  });

  describe('setConfig', () => {
    let closeReopenReportToggle;
    const dropdownList = {};
    const dropdownTrigger = {};
    const button = {};
    let config;

    beforeEach(() => {
      closeReopenReportToggle = new CloseReopenReportToggle({
        dropdownTrigger,
        dropdownList,
        button,
      });

      config = closeReopenReportToggle.setConfig();
    });

    it('returns a config object', () => {
      expect(config).toEqual({
        InputSetter: [
          {
            input: button,
            valueAttribute: 'data-text',
            inputAttribute: 'data-value',
          },
          {
            input: button,
            valueAttribute: 'data-text',
            inputAttribute: 'title',
          },
          {
            input: button,
            valueAttribute: 'data-button-class',
            inputAttribute: 'class',
          },
          {
            input: dropdownTrigger,
            valueAttribute: 'data-toggle-class',
            inputAttribute: 'class',
          },
          {
            input: button,
            valueAttribute: 'data-url',
            inputAttribute: 'href',
          },
          {
            input: button,
            valueAttribute: 'data-method',
            inputAttribute: 'data-method',
          },
        ],
      });
    });
  });
});
