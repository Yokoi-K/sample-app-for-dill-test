# sample-app-for-dill-test

Precompile large local packages and generate dill.

Verify that build time is reduced by injecting `.dill` into the app build using `--import-dill` option at frontend_server.

**Conclusion: although effective, it was found that `--import-dill` does not work during incremental builds.**

## About environment

```
❯ flutter --version
Flutter 3.32.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision fcf2c11572 (4 weeks ago) • 2025-06-24 11:44:07 -0700
Engine • revision dd93de6fb1 (4 weeks ago) • 2025-06-24 07:39:37 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1


❯ dart --version
Dart SDK version: 3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "macos_x64"


❯ which flutter
/Users/user/development/flutter/bin/flutter
```

### App package structure

- packages
  - app (entry point)
    - lib
      - main.dart
  - module_a
  - module_b (heavy source codes)


### Generate `.dill` and verify build time reduction

#### Generate `.dill` for module_b

At first, run `flutter pub get` to create `.dart_tool/package_config.json`

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/user/development/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot \
  --sdk-root=/Users/user/development/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk \
  --target=flutter \
  --output-dill=module_b.dill \
  --packages=.dart_tool/package_config.json \
  lib/module_b.dart
```

Build time is 7 seconds.

#### Build app without `--import-dill=../module_b/module_b.dill` option

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/user/development/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot \
  --sdk-root=/Users/user/development/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk \
  --target=flutter \
  --output-dill=main.dill \
  --packages=.dart_tool/package_config.json \
  lib/main.dart
```

Build time is 10 seconds.


#### Build app using `--import-dill=../module_b/module_b.dill` option

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/user/development/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot \
  --sdk-root=/Users/user/development/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk \
  --target=flutter \
  --import-dill=../module_b/module_b.dill \
  --output-dill=main.dill \
  --packages=.dart_tool/package_config.json \
  lib/main.dart
```

**Build time is 3 seconds.**

### Verifying at incremental build

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/user/development/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot \
  --sdk-root=/Users/user/development/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk \
  --target=flutter \
  --import-dill=../module_b/module_b.dill \
  --output-dill=main.dill \
  --packages=.dart_tool/package_config.json \
  --incremental
  lib/main.dart
```

Build time is 10 seconds.
It does not work.

#### Cause

This is because incremental build uses `_compilerOptions` instead of `compilerOptions`.

https://github.com/dart-lang/sdk/blob/3.0.6/pkg/frontend_server/lib/frontend_server.dart#L578

#### Try: modify frontend_server and verify

I Changed to `_compilerOptions.additionalDills`.

```
compilerOptions.additionalDills = <Uri>[
  Uri.base.resolveUri(new Uri.file(importDill))
];
↓
_compilerOptions.additionalDills = <Uri>[
  Uri.base.resolveUri(new Uri.file(importDill))
];
```

#### How to make environment for dart-sdk

```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="/Users/user/work/depot_tools:$PATH"

fetch dart
git checkout 3.8.1
gclient sync

vim pkg/frontend_server/lib/frontend_server.dart
```

##### generate aot_snapshot for frontend_server

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dart \
  compile aot-snapshot \
  /Users/user/dart-sdk/sdk/pkg/frontend_server/bin/frontend_server_starter.dart \
  -o /Users/user/dart-sdk/frontend_server_aot.dart.snapshot
```

##### Build app using custom frontend_server

```
/Users/user/development/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
  /Users/user/dart-sdk/frontend_server_aot.dart.snapshot \
  --sdk-root=/Users/user/development/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk \
  --target=flutter \
  --import-dill=../module_b/module_b.dill \
  --output-dill=main.dill \
  --packages=.dart_tool/package_config.json \
  --incremental \
  lib/main.dart
```

But build time is 10 seconds. It does not work.
