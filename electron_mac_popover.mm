#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#include "electron_mac_popover.h"

static IMP g_originalAllowsVibrancy;

static char kDisallowVibrancyKey;

BOOL swizzledAllowsVibrancy(id obj, SEL sel) {
  NSNumber* disallowVibrancy = objc_getAssociatedObject(obj,
                                                        &kDisallowVibrancyKey);

  return !disallowVibrancy.boolValue;
}

Napi::FunctionReference ElectronMacPopover::constructor;

Napi::Object ElectronMacPopover::Init(Napi::Env env, Napi::Object exports) {
  Napi::HandleScope scope(env);

  Napi::Function func = DefineClass(env, "ElectronMacPopover", {
    InstanceMethod("show", &ElectronMacPopover::Show),
    InstanceMethod("close", &ElectronMacPopover::Close),
  });

  constructor = Napi::Persistent(func);
  constructor.SuppressDestruct();

  exports.Set("ElectronMacPopover", func);
  return exports;
}

ElectronMacPopover::ElectronMacPopover(const Napi::CallbackInfo& info)
    : Napi::ObjectWrap<ElectronMacPopover>(info) {
  Napi::Env env = info.Env();

  if (info.Length() < 1) {
    Napi::TypeError::New(env, "Wrong number of arguments")
        .ThrowAsJavaScriptException();
    return;
  }

  if (!info[0].IsBuffer()) {
    Napi::TypeError::New(env, "Native window handle expected")
        .ThrowAsJavaScriptException();
    return;
  }

  content_ = *reinterpret_cast<NSView**>(info[0].As<Napi::Buffer<void*>>().Data());
  if (!content_) {
    Napi::TypeError::New(env, "Invalid native window handle")
        .ThrowAsJavaScriptException();
    return;
  }
}

void ElectronMacPopover::Show(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();

  if (info.Length() < 2) {
    Napi::TypeError::New(env, "Wrong number of arguments")
        .ThrowAsJavaScriptException();
    return;
  }

  if (!info[0].IsBuffer()) {
    Napi::TypeError::New(env, "Native window handle expected")
        .ThrowAsJavaScriptException();
    return;
  }

  if (info.Length() < 1 || !info[1].IsObject()) {
    Napi::TypeError::New(env, "Object expected").ThrowAsJavaScriptException();
    return;
  }

  NSView* positioning_content_view = *reinterpret_cast<NSView**>(
    info[0].As<Napi::Buffer<void*>>().Data());
  if (!positioning_content_view) {
    Napi::TypeError::New(env, "Invalid positioning content view")
        .ThrowAsJavaScriptException();
    return;
  }

  Napi::Object options = info[1].As<Napi::Object>();
  if (options.IsEmpty()) {
    Napi::TypeError::New(env, "Options object expected")
        .ThrowAsJavaScriptException();
    return;
  }

  Napi::Object rect = options.Get("rect").As<Napi::Object>();
  if (rect.IsEmpty()) {
    Napi::TypeError::New(env, "'rect' option is required")
        .ThrowAsJavaScriptException();
    return;
  }
  NSRect positioning_rect =
      NSMakeRect(rect.Get("x").As<Napi::Number>().DoubleValue(),
                 rect.Get("y").As<Napi::Number>().DoubleValue(),
                 rect.Get("width").As<Napi::Number>().DoubleValue(),
                 rect.Get("height").As<Napi::Number>().DoubleValue());

  Napi::Object size_obj = options.Get("size").As<Napi::Object>();
  if (size_obj.IsEmpty()) {
    Napi::TypeError::New(env, "'size' option is required")
        .ThrowAsJavaScriptException();
    return;
  }
  NSSize size = NSMakeSize(size_obj.Get("width").As<Napi::Number>().DoubleValue(),
                           size_obj.Get("height").As<Napi::Number>().DoubleValue());

  std::string behavior = "application-defined";
  if (options.Has("behavior")) {
    behavior = options.Get("behavior").As<Napi::String>().Utf8Value();
  }
  std::string preferred_edge = "max-x-edge";
  if (options.Has("edge")) {
    preferred_edge = options.Get("edge").As<Napi::String>().Utf8Value();
  }
  BOOL animate = false;
  if (options.Has("animate")) {
    animate = options.Get("animate").As<Napi::Boolean>().Value();
  }
  std::string appearance = "aqua";
  if (options.Has("appearance")) {
    appearance = options.Get("appearance").As<Napi::String>().Utf8Value();
  }

  NSPopoverBehavior popover_behavior = NSPopoverBehaviorApplicationDefined;
  if (behavior == "transient") {
    popover_behavior = NSPopoverBehaviorTransient;
  } else if (behavior == "semi-transient") {
    popover_behavior = NSPopoverBehaviorSemitransient;
  }

  NSRectEdge popover_edge = NSMaxXEdge;
  if (preferred_edge == "max-y-edge") {
    popover_edge = NSMaxYEdge;
  } else if (preferred_edge == "min-x-edge") {
    popover_edge = NSMinXEdge;
  } else if (preferred_edge == "min-y-edge") {
    popover_edge = NSMinYEdge;
  }

  NSAppearanceName popover_appearance = NSAppearanceNameAqua;
  if (appearance == "vibrantLight") {
    popover_appearance = NSAppearanceNameVibrantLight;
  }
  if (@available(macOS 10.14, *)) {
    if (appearance == "darkAqua") {
      popover_appearance = NSAppearanceNameDarkAqua;
    } else if (appearance == "accessibilityHighContrastAqua") {
      popover_appearance = NSAppearanceNameAccessibilityHighContrastAqua;
    } else if (appearance == "accessibilityHighContrastDarkAqua") {
      popover_appearance = NSAppearanceNameAccessibilityHighContrastDarkAqua;
    } else if (appearance == "accessibilityHighContrastVibrantLight") {
      popover_appearance = NSAppearanceNameAccessibilityHighContrastVibrantLight;
    } else if (appearance == "accessibilityHighContrastVibrantDark") {
      popover_appearance = NSAppearanceNameAccessibilityHighContrastVibrantDark;
    }
  }

  if (!popover_) {
    NSViewController* view_controller =
        [[[NSViewController alloc] init] autorelease];
    NSPopover* popover = [[NSPopover alloc] init];

    [popover setContentViewController:view_controller];

    [content_ setWantsLayer:YES];
    NSView *view = content_.subviews.lastObject.subviews.lastObject;
    if (!view) {
      Napi::Error::New(env, "Missing content view")
          .ThrowAsJavaScriptException();
      return;
    }

    objc_setAssociatedObject(view,
                             &kDisallowVibrancyKey,
                             @(YES),
                             OBJC_ASSOCIATION_COPY_NONATOMIC);

    [popover.contentViewController setView:view];

    [popover setContentSize:size];

	[popover setAppearance:[NSAppearance appearanceNamed:popover_appearance]];

    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSPopoverDidCloseNotification
                    object:popover
                    queue:nil
                usingBlock:^(NSNotification* notification) {
                  PopoverWindowClosed();
                }];

    popover_closed_observer_ = observer;
    popover_ = popover;
  } else if (popover_.shown) {
    return;
  }

  [popover_ setBehavior:popover_behavior];
  [popover_ setAnimates:animate];

  [popover_ showRelativeToRect:positioning_rect
                        ofView:positioning_content_view
                 preferredEdge:popover_edge];
}

void ElectronMacPopover::Close(const Napi::CallbackInfo& info) {
  if (popover_) {
    [popover_ close];
  }
}

void ElectronMacPopover::PopoverWindowClosed() {
  if (popover_closed_observer_) {
    [[NSNotificationCenter defaultCenter]
        removeObserver:popover_closed_observer_];
    popover_closed_observer_ = nullptr;
  }
  if (content_ && popover_) {
    if (content_.subviews.lastObject && popover_.contentViewController.view) {
      [content_.subviews.lastObject addSubview:popover_.contentViewController.view];
    }
  }
  popover_ = nullptr;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  auto allowsVibrancyMethod = class_getInstanceMethod(
    NSClassFromString(@"WebContentsViewCocoa"),
    NSSelectorFromString(@"allowsVibrancy"));
  if (allowsVibrancyMethod) {
    g_originalAllowsVibrancy = method_setImplementation(allowsVibrancyMethod,
      (IMP)&swizzledAllowsVibrancy);
  }
  return ElectronMacPopover::Init(env, exports);
}

NODE_API_MODULE(electron_mac_popover, Init)
