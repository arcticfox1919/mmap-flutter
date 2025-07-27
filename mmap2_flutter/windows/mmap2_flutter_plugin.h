#ifndef FLUTTER_PLUGIN_MMAP2_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_MMAP2_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mmap2_flutter {

class Mmap2FlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  Mmap2FlutterPlugin();

  virtual ~Mmap2FlutterPlugin();

  // Disallow copy and assign.
  Mmap2FlutterPlugin(const Mmap2FlutterPlugin&) = delete;
  Mmap2FlutterPlugin& operator=(const Mmap2FlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mmap2_flutter

#endif  // FLUTTER_PLUGIN_MMAP2_FLUTTER_PLUGIN_H_
