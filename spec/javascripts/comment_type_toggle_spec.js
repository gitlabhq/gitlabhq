import CommentTypeToggle from '~/comment_type_toggle';
import * as dropLabSrc from '~/droplab/drop_lab';
import InputSetter from '~/droplab/plugins/input_setter';

describe('CommentTypeToggle', function () {
  describe('class constructor', function () {
    beforeEach(function () {
      this.dropdownTrigger = {};
      this.dropdownList = {};
      this.noteTypeInput = {};
      this.submitButton = {};
      this.closeButton = {};

      this.commentTypeToggle = new CommentTypeToggle(
        this.dropdownTrigger,
        this.dropdownList,
        this.noteTypeInput,
        this.submitButton,
        this.closeButton,
      );
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
  });

  describe('initDroplab', function () {
    beforeEach(function () {
      this.commentTypeToggle = {
        dropdownTrigger: {},
        dropdownList: {},
        noteTypeInput: {},
        submitButton: {},
        closeButton: {},
      };

      this.droplab = jasmine.createSpyObj('droplab', ['init']);

      spyOn(dropLabSrc, 'default').and.returnValue(this.droplab);

      this.initDroplab = CommentTypeToggle.prototype.initDroplab.call(this.commentTypeToggle);
    });

    it('should instantiate a DropLab instance', function () {
      expect(dropLabSrc.default).toHaveBeenCalled();
    });

    it('should set .droplab', function () {
      expect(this.commentTypeToggle.droplab).toBe(this.droplab);
    });

    it('should call DropLab.prototype.init', function () {
      expect(this.droplab.init).toHaveBeenCalledWith(
        this.commentTypeToggle.dropdownTrigger,
        this.commentTypeToggle.dropdownList,
        [InputSetter],
        {
          InputSetter: [{
            input: this.commentTypeToggle.noteTypeInput,
            valueAttribute: 'data-value',
          }, {
            input: this.commentTypeToggle.submitButton,
            valueAttribute: 'data-button-text',
          },
          {
            input: this.commentTypeToggle.closeButton,
            valueAttribute: 'data-secondary-button-text',
          }, {
            input: this.commentTypeToggle.closeButton,
            valueAttribute: 'data-secondary-button-text',
            inputAttribute: 'data-alternative-text',
          }],
        },
      );
    });

    describe('if no .closeButton is provided', function () {
      beforeEach(function () {
        this.commentTypeToggle = {
          dropdownTrigger: {},
          dropdownList: {},
          noteTypeInput: {},
          submitButton: {},
        };

        this.initDroplab = CommentTypeToggle.prototype.initDroplab.call(this.commentTypeToggle);
      });

      it('should not add .closeButton related InputSetter config', function () {
        expect(this.droplab.init).toHaveBeenCalledWith(
          this.commentTypeToggle.dropdownTrigger,
          this.commentTypeToggle.dropdownList,
          [InputSetter],
          {
            InputSetter: [{
              input: this.commentTypeToggle.noteTypeInput,
              valueAttribute: 'data-value',
            }, {
              input: this.commentTypeToggle.submitButton,
              valueAttribute: 'data-button-text',
            }],
          },
        );
      });
    });
  });
});
