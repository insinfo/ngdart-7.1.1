import 'package:ngdart/src/core/linker.dart';
import 'package:ngdart/src/meta.dart';
import 'package:ngdart/src/runtime/check_binding.dart';

/// Causes an element and its contents to be conditionally added/removed from
/// the DOM based on the value of the given boolean template expression.
///
/// For details, see the [`ngIf` discussion in the Template Syntax][guide] page.
///
/// ### Examples
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgIf-1)"?>
/// ```html
/// <hero-detail *ngIf="isActive"></hero-detail>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (asterisk)"?>
/// ```html
/// <div *ngIf="hero != null" >{{hero.name}}</div>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (ngif-template)"?>
/// ```html
/// <template [ngIf]="hero != null">
///   <div>{{hero.name}}</div>
/// </template>
/// ```
///
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngIf
@Directive(
  selector: '[ngIf]',
)
class NgIf {
  final TemplateRef _templateRef;
  final ViewContainerRef _viewContainer;

  bool _prevCondition = false;

  NgIf(this._viewContainer, this._templateRef);

  /// Whether the content of the directive should be visible.
  @Input()
  set ngIf(bool newCondition) {
    // Legacy support for cases where `null` is still passed to NgIf.
    newCondition = newCondition == true;
    if (!checkBinding(_prevCondition, newCondition)) {
      return;
    }
    if (newCondition) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
    _prevCondition = newCondition;
  }
}
