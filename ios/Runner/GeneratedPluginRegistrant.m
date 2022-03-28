//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<compasstools/CompasstoolsPlugin.h>)
#import <compasstools/CompasstoolsPlugin.h>
#else
@import compasstools;
#endif

#if __has_include(<flutter_bluetooth_serial/FlutterBluetoothSerialPlugin.h>)
#import <flutter_bluetooth_serial/FlutterBluetoothSerialPlugin.h>
#else
@import flutter_bluetooth_serial;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CompasstoolsPlugin registerWithRegistrar:[registry registrarForPlugin:@"CompasstoolsPlugin"]];
  [FlutterBluetoothSerialPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBluetoothSerialPlugin"]];
}

@end
