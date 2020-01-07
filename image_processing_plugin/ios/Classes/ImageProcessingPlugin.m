#import "ImageProcessingPlugin.h"
#if __has_include(<image_processing_plugin/image_processing_plugin-Swift.h>)
#import <image_processing_plugin/image_processing_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "image_processing_plugin-Swift.h"
#endif

@implementation ImageProcessingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImageProcessingPlugin registerWithRegistrar:registrar];
}
@end
