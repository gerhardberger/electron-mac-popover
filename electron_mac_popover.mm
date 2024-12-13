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

  Napi::Object options = info[1].As<Napi::Object>();

  Napi::Object rect = options.Get("rect").As<Napi::Object>();
  NSRect positioning_rect =
      NSMakeRect(rect.Get("x").As<Napi::Number>().DoubleValue(),
                 rect.Get("y").As<Napi::Number>().DoubleValue(),
                 rect.Get("width").As<Napi::Number>().DoubleValue(),
                 rect.Get("height").As<Napi::Number>().DoubleValue());

  Napi::Object size_obj = options.Get("size").As<Napi::Object>();
  NSSize size = NSMakeSize(size_obj.Get("width").As<Napi::Number>().DoubleValue(),
                           size_obj.Get("height").As<Napi::Number>().DoubleValue());

  std::string behavior = options.Get("behavior").As<Napi::String>().Utf8Value();
  std::string preferred_edge = options.Get("edge").As<Napi::String>().Utf8Value();
  BOOL animate = options.Get("animate").As<Napi::Boolean>().Value();

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

  if (!popover_) {
    NSViewController* view_controller =
        [[[NSViewController alloc] init] autorelease];
    NSPopover* popover = [[NSPopover alloc] init];

    [popover setContentViewController:view_controller];

    [content_ setWantsLayer:YES];
    NSView *view = content_.subviews.lastObject.subviews.lastObject;

    objc_setAssociatedObject(view,
                             &kDisallowVibrancyKey,
                             @(YES),
                             OBJC_ASSOCIATION_COPY_NONATOMIC);

    [popover.contentViewController setView:view];

    [popover setContentSize:size];

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
  [[NSNotificationCenter defaultCenter]
      removeObserver:popover_closed_observer_];

  // Add back view to BrowserWindow.
  [content_.subviews.lastObject addSubview:popover_.contentViewController.view];

  popover_closed_observer_ = nullptr;
  popover_ = nullptr;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  auto allowsVibrancyMethod = class_getInstanceMethod(
    NSClassFromString(@"WebContentsViewCocoa"),
    NSSelectorFromString(@"allowsVibrancy"));

  g_originalAllowsVibrancy = method_setImplementation(allowsVibrancyMethod,
    (IMP)&swizzledAllowsVibrancy);

  return ElectronMacPopover::Init(env, exports);
}

NODE_API_MODULE(electron_mac_popover, Init)
