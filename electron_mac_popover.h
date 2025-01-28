#ifndef ELECTRON_MAC_POPOVER_H
#define ELECTRON_MAC_POPOVER_H

#include <napi.h>

class ElectronMacPopover : public Napi::ObjectWrap<ElectronMacPopover> {
 public:
  static Napi::Object Init(Napi::Env env, Napi::Object exports);
  ElectronMacPopover(const Napi::CallbackInfo& info);

 private:
  static Napi::FunctionReference constructor;

  void Show(const Napi::CallbackInfo& info);
  void Close(const Napi::CallbackInfo& info);

  void PopoverWindowClosed();
  void SetupClosedCallback(const Napi::CallbackInfo &info);

  NSPopover* popover_;
  NSView* content_;
  id popover_closed_observer_;
};

#endif
