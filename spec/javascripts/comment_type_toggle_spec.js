import CommentTypeToggle from '~/comment_type_toggle';
import InputSetter from '~/droplab/plugins/input_setter';

describe('CommentTypeToggle', function () {
  describe('class constructor', function () {
    beforeEach(function () {
      this.dropdownTrigger = {};
      this.dropdownList = {};
      this.noteTypeInput = {};
      this.submitButton = {};
      this.closeButton = {};

      this.commentTypeToggle = new CommentTypeToggle({
        dropdownTrigger: this.dropdownTrigger,
        dropdownList: this.dropdownList,
        noteTypeInput: this.noteTypeInput,
        submitButton: this.submitButton,
        closeButton: this.closeButton,
      });
    });

    it('should set .dropdownTrigger', function () {
      expect(this.commentTypeToggle.dropdownTrigger).toBe(this.dropdownTrigger);
    });

    it('should set .dropdownList', function () {
      expect(this.commentTypeToggle.dropdownList).toBe(this.dropdownList);
    });

    it('should set .noteTypeInput', function () {
      expect(this.commentTypeToggle.noteTypeInput).toBe(this.noteTypeInput);
    });

    it('should set .submitButton', function () {
      expect(this.commentTypeToggle.submitButton).toBe(this.submitButton);
    });

    it('should set .closeButton', function () {
      expect(this.commentTypeToggle.closeButton).toBe(this.closeButton);
    });

    it('should set .reopenButton', function () {
      expect(this.commentTypeToggle.reopenButton).toBe(this.reopenButton);
    });
  });

  describe('initDroplab', function () {
    beforeEach(function () {
      this.commentTypeToggle = {
        dropdownTrigger: {},
        dropdownList: {},
        noteTypeInput: {},
        submitButton: {},
        closeButton: {},
        setConfig: () => {},
      };
      this.config = {};

      this.droplab = jasmine.createSpyObj('droplab', ['init']);

      this.droplabConstructor = spyOnDependency(CommentTypeToggle, 'DropLab').and.returnValue(this.droplab);
      spyOn(this.commentTypeToggle, 'setConfig').and.returnValue(this.config);

      CommentTypeToggle.prototype.initDroplab.call(this.commentTypeToggle);
    });

    it('should instantiate a DropLab instance', function () {
      expect(this.droplabConstructor).toHaveBeenCalled();
    });

    it('should set .droplab', function () {
      expect(this.commentTypeToggle.droplab).toBe(this.droplab);
    });

    it('should call .setConfig', function () {
      expect(this.commentTypeToggle.setConfig).toHaveBeenCalled();
    });

    it('should call DropLab.prototype.init', function () {
      expect(this.droplab.init).toHaveBeenCalledWith(
        this.commentTypeToggle.dropdownTrigger,
        this.commentTypeToggle.dropdownList,
        [InputSetter],
        this.config,
      );
    });
  });

  describe('setConfig', function () {
    describe('if no .closeButton is provided', function () {
      beforeEach(function () {
        this.commentTypeToggle = {
          dropdownTrigger: {},
          dropdownList: {},
          noteTypeInput: {},
          submitButton: {},
          reopenButton: {},
        };

        this.setConfig = CommentTypeToggle.prototype.setConfig.call(this.commentTypeToggle);
      });

      it('should not add .closeButton related InputSetter config', function () {
        expect(this.setConfig).toEqual({
          InputSetter: [{
            input: this.commentTypeToggle.noteTypeInput,
            valueAttribute: 'data-value',
          }, {
            input: this.commentTypeToggle.submitButton,
            valueAttribute: 'data-submit-text',
          }, {
            input: this.commentTypeToggle.reopenButton,
            valueAttribute: 'data-reopen-text',
          }, {
            input: this.commentTypeToggle.reopenButton,
            valueAttribute: 'data-reopen-text',
            inputAttribute: 'data-alternative-text',
          }],
        });
      });
    });

    describe('if no .reopenButton is provided', function () {
      beforeEach(function () {
        this.commentTypeToggle = {
          dropdownTrigger: {},
          dropdownList: {},
          noteTypeInput: {},
          submitButton: {},
          closeButton: {},
        };

        this.setConfig = CommentTypeToggle.prototype.setConfig.call(this.commentTypeToggle);
      });

      it('should not add .reopenButton related InputSetter config', function () {
        expect(this.setConfig).toEqual({
          InputSetter: [{
            input: this.commentTypeToggle.noteTypeInput,
            valueAttribute: 'data-value',
          }, {
            input: this.commentTypeToggle.submitButton,
            valueAttribute: 'data-submit-text',
          }, {
            input: this.commentTypeToggle.closeButton,
            valueAttribute: 'data-close-text',
          }, {
            input: this.commentTypeToggle.closeButton,
            valueAttribute: 'data-close-text',
            inputAttribute: 'data-alternative-text',
          }],
        });
      });
    });
  });
});
