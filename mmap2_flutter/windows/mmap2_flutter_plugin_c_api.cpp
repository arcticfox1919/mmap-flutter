#include "include/mmap2_flutter/mmap2_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mmap2_flutter_plugin.h"

void Mmap2FlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mmap2_flutter::Mmap2FlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
