(function () {
  function Print(ysy) {
    this.printReady = false;
    this.$area = null;
    this.ysy = ysy;
    this.patch(ysy);
  }

  Print.prototype.margins = {
    left: 10,
    right: 10,
    top: 20,
    bottom: 10
  };
  Print.prototype.patch = function (ysy) {
    var self = this;
    var mediaQueryList = window.matchMedia('print');
    mediaQueryList.addListener(function (mql) {
      if (mql.matches) {
        self.beforePrint();
      } else {
        self.afterPrint();
      }
    });
    window.onbeforeprint = $.proxy(this.beforePrint, this);
    window.onafterprint = $.proxy(this.afterPrint, this);
  };
  Print.prototype.directPrint = function () {
    this.beforePrint();
    window.print();
    this.afterPrint();
  };
  Print.prototype.beforePrint = function () {
    if (this.printReady) return;
    this.ysy.mapModel.resetView();
    this.$area = this.createPrintArea();
    $("body").append(this.$area);
    $("#wrapper").hide();
    this.printReady = true;
    return this.$area;
  };
  Print.prototype.afterPrint = function () {
    if (!this.printReady) return;
    this.$area.remove();
    $("#wrapper").show();
    this.ysy.mapModel.resetView();
    this.printReady = false;
  };
  Print.prototype.createPrintArea = function () {
    var $stage = this.ysy.$container.children();
    // var width = $stage.width();
    // var height = $stage.height();
    var stripWidth = 330;
    var children = $stage.children(":not(:hidden)");
    var dims = this.getStageDims(children);
    var $area = $('<div id="mindmup__print-area" class="mindmup__print-area mindmup__print-area--stripped scheme-by-' + this.ysy.styles.setting + '"></div>');
    for (var p = dims.left - this.margins.left; p < dims.right + this.margins.right; p += stripWidth) {
      $area.append(this.createStrip(children, dims, p, p + stripWidth));
    }
    return $area;
  };
  Print.prototype.createStrip = function (children, dims, start, end) {
    /* start can be negative*/
    if (end <= start) return null;
    // var stageOffset = $stage.height();
    var $strip = $('<div class="mindmup__print-strip" style="height:' + (dims.bottom - dims.top + this.margins.top + this.margins.bottom) + 'px;width:' + (end - start) + 'px"></div>');
    // var children = $stage.children(":not(:hidden)");
    var added = 0;
    var topEdge = dims.top - this.margins.top;
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var left = parseInt(child.style.left);
      var width = child.offsetWidth;
      if (left > end + 5) continue;
      if (left + width < start - 5) continue;
      added++;
      $strip.append(
          $(child)
              .clone()
              .css({
                left: left - start,
                top: parseInt(child.style.top) - topEdge,
                width: width
              })
      );
    }
    if (!added) return null;
    return $strip;
  };
  Print.prototype.getStageDims = function (children) {
    var dims = {
      left: Infinity,
      top: Infinity,
      right: -Infinity,
      bottom: -Infinity
    };
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var left = parseInt(child.style.left);
      var top = parseInt(child.style.top);
      var width = child.offsetWidth;
      var height = child.offsetHeight;
      if (left < dims.left) dims.left = left;
      if (top < dims.top) dims.top = top;
      if (left + width > dims.right) dims.right = left + width;
      if (top + height > dims.bottom) dims.bottom = top + height;
    }
    return dims;
  };

  window.easyMindMupClasses.Print = Print;
  //####################################################################################################################
  /**
   * Button, which prepare Mind Map into printable version
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @constructor
   */
  function PrintButton(ysy, $parent) {
    this.$element = null;
    this.ysy = ysy;
    this.init(ysy, $parent);
  }

  PrintButton.prototype.id = "PrintButton";

  /**
   *
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @return {PrintButton}
   */
  PrintButton.prototype.init = function (ysy, $parent) {
    this.$element = $parent.find(".mindmup-button-print");
    var self = this;
    this.$element.click(function () {
      self.ysy.print.directPrint();
    });
    return this;
  };
  PrintButton.prototype._render = function () {
  };

  window.easyMindMupClasses.PrintButton = PrintButton;

})();
