"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
exports.__esModule = true;
var Lint = require("tslint");
var Rule = (function (_super) {
    __extends(Rule, _super);
    function Rule() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Rule.prototype.apply = function (sourceFile) {
        return this.applyWithWalker(new NoDogsWalker(sourceFile, this.getOptions()));
    };
    return Rule;
}(Lint.Rules.AbstractRule));
Rule.FAILURE_STRING = "Bow!";
exports.Rule = Rule;
// The walker takes care of all the work.
var NoDogsWalker = (function (_super) {
    __extends(NoDogsWalker, _super);
    function NoDogsWalker() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    NoDogsWalker.prototype.visitFunctionDeclaration = function (node) {
        if (node.getText().match(/dog/i)) {
            // create a failure at the current position
            this.addFailure(this.createFailure(node.getStart(), node.getWidth(), Rule.FAILURE_STRING));
        }
        // call the base version of this visitor to actually parse this node
        _super.prototype.visitFunctionDeclaration.call(this, node);
    };
    return NoDogsWalker;
}(Lint.RuleWalker));
