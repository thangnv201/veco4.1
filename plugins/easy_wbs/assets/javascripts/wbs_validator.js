/**
 * Created by hosekp on 11/14/16.
 */
(function () {
  var classes = window.easyMindMupClasses;

  function WbsValidator(ysy) {
    classes.Validator.call(this,ysy);
  }
  classes.extendClass(WbsValidator,classes.Validator);

  WbsValidator.prototype.changeParent = function (child, newParent) {
    if(child.attr.nonEditable) return false;
    var childData = this.ysy.getData(child);
    if (!childData.tracker_id) return true;
    var tracker = _.find(this.ysy.dataStorage.get("trackers"), function (item) {
      return item.id === childData.tracker_id;
    });
    if (!tracker.subtaskable) {
      if (newParent.attr && newParent.attr.isProject) return true;
      showFlashMessageWBS("error", this.ysy.settings.labels.errors.not_subtaskable.replace("%{task_name}", child.title));
      return false;
    }
    return true;

  };


  classes.WbsValidator = WbsValidator;
})();

window.showFlashMessageWBS = (function (type, message, delay) {
  var $content = $("#content");
  $content.find(".flash").remove();
  var element = document.createElement("div");
  element.className = 'fixed flash ' + type;
  element.style.position = 'fixed';
  element.style.zIndex = '10001';
  element.style.right = '5px';
  element.style.top = '100px';
  element.setAttribute("onclick", "closeFlashMessage($(this))");
  var close = document.createElement("a");
  close.className = 'icon-close close-icon';
  close.setAttribute("href", "javascript:void(0)");
  close.style.float = 'right';
  close.style.marginLeft = '5px';
  // close.setAttribute("onclick", "closeFlashMessage($(this))");
  var span = document.createElement("span");
  span.innerHTML = message;
  element.appendChild(close);
  element.appendChild(span);
  $content.prepend(element);
  var $element = $(element);
  if (delay) {
    setTimeout(function () {
      window.requestAnimationFrame(function () {
        closeFlashMessage($element);
      });
    }, delay);
  }
  return $element;
});

window.closeFlashMessage = (function ($element) {
  $element.closest('.flash').fadeOut(500, function () {
    $element.remove();
  });
});