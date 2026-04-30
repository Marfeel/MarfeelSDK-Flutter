# Experiences & Recirculation — Flutter Plugin Implementation Plan

## Context

Marfeel's web Experiences platform now has native iOS and Android parity (iOS `main` commit `b696b8f`, Android branch `experiences-api`, PR #43). This plan ports those two public APIs to the Flutter plugin (`marfeel_sdk`) so Dart consumers can:

- **Recirculation**: track `eligible`, `impression`, `click` events on named modules with link lists.
- **Experiences**: fetch server-configured experiences for the current page, run client-side experiment assignment + frequency capping, resolve content, and track lifecycle events (`eligible`, `impression`, `click`, `close`).

The heavy lifting (URL building, response parsing, persistence, content resolution, sentinel-link augmentation, wire-format parity) lives in the native SDKs. The Flutter layer is a **thin bridge**: it serialises the same call shape that already works on iOS / Android over the existing `MethodChannel` (`com.marfeel.sdk/compass`) and reconstructs the result objects in Dart.

**Reference implementations** (already shipped, do not re-design):
- iOS: `/Users/miquelmasriera/Marfeel/MarfeelSDK-iOS/CompassSDK/Experiences/`
- Android: `/Users/miquelmasriera/Marfeel/MarfeelSDK-Android/compass/src/main/java/com/marfeel/compass/experiences/`
- iOS port plan (source of truth for wire format & semantics): `./ios_impl_plan.md`

**This plan does not re-derive design decisions**; it only describes how to surface the existing native API in Dart and route calls through the method channel.

---

## Public Dart API (target shape)

```dart
// Singletons (mirror existing CompassTracking / MultimediaTracking pattern — static methods)
class Recirculation {
  static void trackEligible({required String name, required List<RecirculationLink> links});
  static void trackImpression({required String name, required List<RecirculationLink> links});
  static void trackImpressionLink({required String name, required RecirculationLink link});
  static void trackClick({required String name, required RecirculationLink link});
}

class Experiences {
  static void addTargeting(String key, String value);

  static Future<List<Experience>> fetchExperiences({
    ExperienceType? filterByType,
    ExperienceFamily? filterByFamily,
    bool resolve = false,
    String? url,
  });

  static void trackEligible({required Experience experience, required List<RecirculationLink> links});
  static void trackImpression({required Experience experience, required List<RecirculationLink> links});
  static void trackImpressionLink({required Experience experience, required RecirculationLink link});
  static void trackClick({required Experience experience, required RecirculationLink link});
  static void trackClose(Experience experience);

  // QA / Debug
  static void clearFrequencyCaps();
  static Future<Map<String, int>> getFrequencyCapCounts(String experienceId);
  static Future<Map<String, List<String>>> getFrequencyCapConfig();
  static void clearReadEditorials();
  static Future<List<String>> getReadEditorials();
  static Future<Map<String, String>> getExperimentAssignments();
  static void setExperimentAssignment({required String groupId, required String variantId});
  static void clearExperimentAssignments();

  // Content resolution after fetch (per-experience, not via fetchExperiences resolve flag)
  static Future<String?> resolveExperience(Experience experience);
}
```

Static methods on a non-instantiable class match the existing `CompassTracking._()` and `MultimediaTracking._()` style (`lib/src/compass_tracking.dart:11`).

---

## File Layout

```
lib/
├── marfeel_sdk.dart                       # add exports for new files
└── src/
    ├── compass_tracking.dart              # untouched
    ├── multimedia_tracking.dart           # untouched
    ├── compass_scroll_view.dart           # untouched
    ├── method_channel.dart                # untouched
    ├── types.dart                         # untouched (existing types stay here)
    ├── experiences/                       # NEW
    │   ├── recirculation.dart             # Recirculation static API
    │   ├── experiences.dart               # Experiences static API
    │   └── models.dart                    # Experience, RecirculationLink, enums, ExperienceFilter, ExperienceSelector
    └── ...

test/
├── recirculation_test.dart                # NEW
├── experiences_test.dart                  # NEW
└── experiences_models_test.dart           # NEW

ios/Classes/MarfeelSdkPlugin.swift         # add new method-call cases
android/src/main/kotlin/com/marfeel/flutter/MarfeelSdkPlugin.kt   # add new method-call cases

example/lib/screens/experiences_screen.dart  # NEW demo screen
example/lib/main.dart                        # add Experiences tab
```

> **Why a sub-folder for experiences?** The current `lib/src/` is flat and small. Experiences brings ~3 new files plus models that are cohesive but only relevant to this feature. Grouping them in `experiences/` keeps `compass_tracking.dart` discoverable and avoids bloating `types.dart`. The barrel `marfeel_sdk.dart` re-exports so consumers do a single `import 'package:marfeel_sdk/marfeel_sdk.dart'`.

---

## Phase 1: Dart Models (`lib/src/experiences/models.dart`)

All models are pure data — no platform calls. Mirrors the iOS shapes 1:1 since the method channel will pass dictionaries with iOS-style keys (the iOS plugin already does this for RFV/multimedia metadata, see `ios/Classes/MarfeelSdkPlugin.swift:75-90`).

### 1.1 `RecirculationLink`
```dart
class RecirculationLink {
  final String url;
  final int position;
  const RecirculationLink({required this.url, required this.position});

  Map<String, dynamic> toMap() => {'url': url, 'position': position};
}
```
Sent across the channel as a `Map`. Serialised to native `RecirculationLink(url:, position:)` (iOS) / `RecirculationLink(url, position)` (Android) on the other side.

### 1.2 `ExperienceType` enum
Mirror of iOS `ExperienceType` (`MarfeelSDK-iOS/.../ExperienceType.swift`):
```dart
enum ExperienceType {
  inline('inline'),
  flowcards('flowcards'),
  compass('compass'),
  adManager('adManager'),
  affiliationEnhancer('affiliationEnhancer'),
  conversions('conversions'),
  content('content'),
  experiments('experiments'),
  experimentation('experimentation'),
  recirculation('recirculation'),
  goalTracking('goalTracking'),
  ecommerce('ecommerce'),
  multimedia('multimedia'),
  piano('piano'),
  appBanner('appBanner'),
  unknown('unknown');

  const ExperienceType(this.value);
  final String value;

  static ExperienceType? fromKey(String? key) {
    if (key == null) return null;
    for (final t in ExperienceType.values) {
      if (t.value == key) return t;
    }
    return null;
  }
}
```
**Wire convention:** Dart sends the `value` string to native; native maps back via its `fromKey`. This avoids depending on Dart enum index ordering matching native ordering.

### 1.3 `ExperienceFamily` enum
Same pattern. Values map to server keys (`twitterexperience`, `recommenderexperience`, `marfeelsocial`, etc. — full list in `MarfeelSDK-iOS/.../ExperienceFamily.swift`). `fromKey` returns `.unknown` on unrecognised key when present in payload, but the field itself is **nullable** in `Experience` (absent in JSON → `null`).

### 1.4 `ExperienceContentType` enum
Same pattern. Values: `TextHTML`, `Json`, `AMP`, `WidgetProvider`, `AdServer`, `Container`, `Unknown`. Falls back to `unknown`.

### 1.5 `ExperienceSelector` / `ExperienceFilter`
```dart
class ExperienceSelector {
  final String selector;
  final String strategy;
  const ExperienceSelector({required this.selector, required this.strategy});
  factory ExperienceSelector.fromMap(Map<dynamic, dynamic> m) =>
      ExperienceSelector(selector: m['selector'] as String, strategy: m['strategy'] as String);
}

class ExperienceFilter {
  final String key;
  final String operator;     // "eq", "neq", "contains", … (iOS ExperienceFilterOperator.key)
  final List<String> values;
  const ExperienceFilter({required this.key, required this.operator, required this.values});
  factory ExperienceFilter.fromMap(Map<dynamic, dynamic> m) => ExperienceFilter(
        key: m['key'] as String,
        operator: m['operator'] as String,
        values: (m['values'] as List).cast<String>(),
      );
}
```
`operator` exposed as plain `String` rather than mirroring `ExperienceFilterOperator` (8 enum values × 2 keys each). The native side already exposes `key` strings — passing them through is simpler and lets new operators ship without a Dart release.

### 1.6 `Experience`
```dart
class Experience {
  final String id;
  final String name;
  final ExperienceType type;
  final ExperienceFamily? family;
  final String? placement;
  final String? contentUrl;
  final ExperienceContentType contentType;
  final Map<String, dynamic>? features;
  final String? strategy;
  final List<ExperienceSelector>? selectors;
  final List<ExperienceFilter>? filters;
  final Map<String, dynamic> rawJson;
  String? resolvedContent;   // mutable: filled by Experiences.resolveExperience(...)

  Experience({
    required this.id,
    required this.name,
    required this.type,
    required this.family,
    required this.placement,
    required this.contentUrl,
    required this.contentType,
    required this.features,
    required this.strategy,
    required this.selectors,
    required this.filters,
    required this.rawJson,
    this.resolvedContent,
  });

  factory Experience.fromMap(Map<dynamic, dynamic> m) { ... }
}
```

**Why `resolvedContent` is mutable:** matches iOS `public internal(set) var resolvedContent: String?`. After `Experiences.resolveExperience(exp)` returns, the same Dart instance gets its `resolvedContent` populated so subsequent `resolve` calls short-circuit. (Alternative: return a new immutable instance from `resolveExperience`. Mutation is uglier but matches the native semantics and the way consumers are likely to iterate over a stored list.)

**Why `rawJson: Map<String, dynamic>`**: pass-through escape hatch for fields not yet typed in the bridge. Same role as iOS `[String: Any]`.

---

## Phase 2: Dart `Recirculation` API (`lib/src/experiences/recirculation.dart`)

```dart
class Recirculation {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;
  Recirculation._();

  static void trackEligible({required String name, required List<RecirculationLink> links}) {
    _channel.invokeMethod('recirculation.trackEligible', {
      'name': name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpression({required String name, required List<RecirculationLink> links}) {
    _channel.invokeMethod('recirculation.trackImpression', {
      'name': name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpressionLink({required String name, required RecirculationLink link}) {
    _channel.invokeMethod('recirculation.trackImpressionLink', {
      'name': name,
      'link': link.toMap(),
    });
  }

  static void trackClick({required String name, required RecirculationLink link}) {
    _channel.invokeMethod('recirculation.trackClick', {
      'name': name,
      'link': link.toMap(),
    });
  }
}
```

**Method-name convention:** `feature.method` (`recirculation.trackImpression`, `experiences.fetch`). Existing methods (`trackNewPage`, `getRFV`, `initializeMultimediaItem`) are namespace-free; new methods use a dotted prefix to avoid collision and keep the iOS / Kotlin `switch` blocks readable.

**Two impression overloads:** iOS exposes `trackImpression(name:, links:)` AND `trackImpression(name:, link:)`. We expose them as **two distinct method names** rather than overloading by argument shape — Dart positional args + method-channel string-keyed maps make overload-by-shape ambiguous. `trackImpressionLink` (singular link) maps to the single-link iOS variant; the native side wraps it into `[link]` and calls the same `(name, [link])` method. (This costs one extra Swift/Kotlin case per impression flavour but keeps the wire contract unambiguous.)

---

## Phase 3: Dart `Experiences` API (`lib/src/experiences/experiences.dart`)

```dart
class Experiences {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;
  Experiences._();

  static void addTargeting(String key, String value) {
    _channel.invokeMethod('experiences.addTargeting', {'key': key, 'value': value});
  }

  static Future<List<Experience>> fetchExperiences({
    ExperienceType? filterByType,
    ExperienceFamily? filterByFamily,
    bool resolve = false,
    String? url,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('experiences.fetch', {
      'filterByType': filterByType?.value,
      'filterByFamily': filterByFamily?.value,
      'resolve': resolve,
      'url': url,
    });
    if (result == null) return const [];
    return result
        .cast<Map<dynamic, dynamic>>()
        .map(Experience.fromMap)
        .toList(growable: false);
  }

  static void trackEligible({required Experience experience, required List<RecirculationLink> links}) {
    _channel.invokeMethod('experiences.trackEligible', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpression({required Experience experience, required List<RecirculationLink> links}) {
    _channel.invokeMethod('experiences.trackImpression', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpressionLink({required Experience experience, required RecirculationLink link}) {
    _channel.invokeMethod('experiences.trackImpressionLink', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'link': link.toMap(),
    });
  }

  static void trackClick({required Experience experience, required RecirculationLink link}) {
    _channel.invokeMethod('experiences.trackClick', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'link': link.toMap(),
    });
  }

  static void trackClose(Experience experience) {
    _channel.invokeMethod('experiences.trackClose', {'experienceId': experience.id});
  }

  static Future<String?> resolveExperience(Experience experience) async {
    final content = await _channel.invokeMethod<String>('experiences.resolve', {
      'experienceId': experience.id,
    });
    experience.resolvedContent = content;
    return content;
  }

  // QA helpers (omitted body for brevity — straight-through invokeMethod calls)
  static void clearFrequencyCaps();
  static Future<Map<String, int>> getFrequencyCapCounts(String experienceId);
  static Future<Map<String, List<String>>> getFrequencyCapConfig();
  static void clearReadEditorials();
  static Future<List<String>> getReadEditorials();
  static Future<Map<String, String>> getExperimentAssignments();
  static void setExperimentAssignment({required String groupId, required String variantId});
  static void clearExperimentAssignments();
}
```

### Critical design points

| Decision | Why |
|---|---|
| Pass **`experienceId` + `experienceName`** instead of full `Experience` map | iOS `Experiences.trackImpression` only needs `experience.id` (for freq cap) and `experience.name` (for recirculation). Android uses `experience.id` for both. Sending only what's needed avoids serialising 12 fields per call and matches Android's narrower signature. *Note the Android/iOS divergence in section "Behaviour parity gap" below.* |
| **`trackEligible` / `trackImpression` etc. on `Experiences` go via a dedicated method**, not by composing Dart-side `Recirculation` calls | Native already wires `Experiences.trackImpression` → `freqCap.trackImpression` + `recirculation.trackImpression`. Doing it Dart-side would skip the freq-cap update on iOS / Android. Also, Android binds `name = experience.id` while iOS binds `name = experience.name` (see "Behaviour parity gap"). Hiding the choice in the native method delegates platform-specific decisions to the existing native code rather than re-deciding in Dart. |
| **`fetchExperiences` is a `Future`**, not callback | Standard Dart pattern (matches existing `getUserId`, `getRFV`). MethodChannel call is async by nature; iOS callback wraps to `result(...)`, Android coroutine wraps to `result.success(...)` (see Phase 4/5). |
| **`resolveExperience` is a separate Future call** rather than a method on `Experience` | `Experience` is a Dart-side data class with no channel handle. Putting `resolve()` on the model would require either a back-reference to the channel (leaking the bridge into the model) or a global call site, which is ugly. The flat static method on `Experiences` is consistent with the rest of the API surface. |
| **`resolve: true` on `fetchExperiences`** is honoured natively | iOS already runs `DispatchGroup` + 10s timeout, Android uses `coroutineScope { … awaitAll() }`. We pass the flag through; native populates a `resolvedContent` field per experience in the returned map. |

### Behaviour parity gap to flag (will need a native-side fix, not Flutter's job to paper over)

iOS `Experiences.trackImpression` calls `recirculation.trackImpression(name: experience.name, …)` (`Experiences.swift:158`).
Android calls `recirculationTracker.trackImpression(experience.id, …)` (`Experiences.kt:67`).

This is a pre-existing native discrepancy. The Flutter bridge should send **both** `experienceId` and `experienceName` and let each platform pick what it needs. **Flag it to the SDK team** — the wire format target ("module name") needs alignment, but that fix lives in iOS or Android, not in the Flutter plugin.

---

## Phase 4: iOS Plugin (`ios/Classes/MarfeelSdkPlugin.swift`)

Add cases to the existing `switch call.method` in `handle(_:result:)` (currently ends at line 234). Each case follows the existing pattern: read args, call native API, call `result(...)`.

### 4.1 Recirculation cases

```swift
case "recirculation.trackEligible":
    let name = args?["name"] as? String ?? ""
    let links = parseLinks(args?["links"])   // helper
    Recirculation.shared.trackEligible(name: name, links: links)
    result(nil)

case "recirculation.trackImpression":
    let name = args?["name"] as? String ?? ""
    let links = parseLinks(args?["links"])
    Recirculation.shared.trackImpression(name: name, links: links)
    result(nil)

case "recirculation.trackImpressionLink":
    let name = args?["name"] as? String ?? ""
    let link = parseLink(args?["link"])
    Recirculation.shared.trackImpression(name: name, link: link)   // single-link overload
    result(nil)

case "recirculation.trackClick":
    let name = args?["name"] as? String ?? ""
    let link = parseLink(args?["link"])
    Recirculation.shared.trackClick(name: name, link: link)
    result(nil)
```

Helpers (private extension on `MarfeelSdkPlugin`):
```swift
private func parseLink(_ raw: Any?) -> RecirculationLink {
    let m = raw as? [String: Any] ?? [:]
    return RecirculationLink(
        url: m["url"] as? String ?? "",
        position: m["position"] as? Int ?? 0
    )
}

private func parseLinks(_ raw: Any?) -> [RecirculationLink] {
    let arr = raw as? [[String: Any]] ?? []
    return arr.map { RecirculationLink(url: $0["url"] as? String ?? "", position: $0["position"] as? Int ?? 0) }
}
```

### 4.2 Experiences cases

```swift
case "experiences.addTargeting":
    let key = args?["key"] as? String ?? ""
    let value = args?["value"] as? String ?? ""
    Experiences.shared.addTargeting(key: key, value: value)
    result(nil)

case "experiences.fetch":
    let filterByType = (args?["filterByType"] as? String).flatMap { ExperienceType(rawValue: $0) }
    let filterByFamily = (args?["filterByFamily"] as? String).flatMap { ExperienceFamily(rawValue: $0) }
    let resolve = args?["resolve"] as? Bool ?? false
    let url = args?["url"] as? String
    Experiences.shared.fetchExperiences(
        filterByType: filterByType,
        filterByFamily: filterByFamily,
        resolve: resolve,
        url: url
    ) { experiences in
        let payload = experiences.map { Self.encodeExperience($0) }
        result(payload)
    }

case "experiences.trackEligible":
    let id = args?["experienceId"] as? String ?? ""
    let name = args?["experienceName"] as? String ?? ""
    let links = parseLinks(args?["links"])
    let exp = stubExperience(id: id, name: name)
    Experiences.shared.trackEligible(experience: exp, links: links)
    result(nil)

// trackImpression / trackImpressionLink / trackClick / trackClose follow the same pattern

case "experiences.resolve":
    // Look up by id from a per-call stash, OR re-fetch — see "Resolve lookup" below
```

**Stub experience problem:** `Experiences.shared.trackImpression(experience:, links:)` takes an `Experience` object, but in Dart we only ship the `id` + `name`. We must reconstruct a synthetic `Experience` instance native-side to pass to the SDK — or change the API contract.

**Approach A — synthetic stub:** create `Experience(id: id, name: name, type: .unknown, …)` from the bridged ID/name and pass it. This works because `Experiences.trackImpression` only reads `experience.id` (for freq cap) and `experience.name` (for recirculation). It does NOT work for `resolve`, which needs `contentUrl` and `contentResolver`.

**Approach B — id-keyed cache native-side:** when `experiences.fetch` runs, store the returned `[Experience]` in a private dictionary keyed by `id` (with a soft eviction policy, e.g., last 200 or last fetch only). `experiences.resolve` and `experiences.trackXxx` look up by id. This preserves full native semantics for resolve. *Recommended.*

A small native-side cache (`private var cachedExperiences: [String: Experience] = [:]`) inside the plugin class, populated from `experiences.fetch`, drained on `stopTracking` or replaced on next fetch. Same approach mirrored in Android.

```swift
private var experienceCache: [String: Experience] = [:]
private let cacheLock = NSLock()

// In experiences.fetch completion:
cacheLock.lock()
experienceCache.removeAll()
for exp in experiences { experienceCache[exp.id] = exp }
cacheLock.unlock()

// In track* / resolve cases:
cacheLock.lock()
let exp = experienceCache[id]
cacheLock.unlock()
guard let exp = exp else { result(nil); return }
```

If the experience is missing (e.g., consumer is tracking an experience from a prior fetch that's been evicted), fall back to a stub for trackImpression/trackEligible/trackClick (id+name suffices). For `resolve`, return `nil` (no content URL known).

### 4.3 `encodeExperience` helper

Serialise an `Experience` to a dictionary that Dart's `Experience.fromMap` understands. Field names match Dart-side keys exactly:

```swift
private static func encodeExperience(_ e: Experience) -> [String: Any?] {
    return [
        "id": e.id,
        "name": e.name,
        "type": e.type.rawValue,
        "family": e.family?.rawValue,
        "placement": e.placement,
        "contentUrl": e.contentUrl,
        "contentType": e.contentType.rawValue,
        "features": e.features,
        "strategy": e.strategy,
        "selectors": e.selectors?.map { ["selector": $0.selector, "strategy": $0.strategy] },
        "filters": e.filters?.map { ["key": $0.key, "operator": $0.`operator`.key, "values": $0.values] },
        "rawJson": e.rawJson,
        "resolvedContent": e.resolvedContent,
    ]
}
```

⚠️ `features` and `rawJson` may contain arbitrary types. The Flutter `StandardMessageCodec` supports `String`, `bool`, `Int`, `Double`, `List`, `Dict` of those types. Anything else (e.g., `NSNumber` boxed differently) must be normalised. In practice the iOS JSON parser already returns `[String: Any]` from `JSONSerialization`, which produces only codec-friendly types — but **add a unit test** that round-trips a fixture response through encode → MethodChannel → decode.

### 4.4 QA cases

```swift
case "experiences.clearFrequencyCaps": Experiences.shared.clearFrequencyCaps(); result(nil)
case "experiences.getFrequencyCapCounts":
    let id = args?["experienceId"] as? String ?? ""
    result(Experiences.shared.getFrequencyCapCounts(experienceId: id))
case "experiences.getFrequencyCapConfig": result(Experiences.shared.getFrequencyCapConfig())
case "experiences.clearReadEditorials": Experiences.shared.clearReadEditorials(); result(nil)
case "experiences.getReadEditorials": result(Experiences.shared.getReadEditorials())
case "experiences.getExperimentAssignments": result(Experiences.shared.getExperimentAssignments())
case "experiences.setExperimentAssignment":
    let groupId = args?["groupId"] as? String ?? ""
    let variantId = args?["variantId"] as? String ?? ""
    Experiences.shared.setExperimentAssignment(groupId: groupId, variantId: variantId)
    result(nil)
case "experiences.clearExperimentAssignments": Experiences.shared.clearExperimentAssignments(); result(nil)
```

### 4.5 Pod dep bump

`ios/marfeel_sdk.podspec` currently pins `MarfeelSDK-iOS ~> 2.18.7`. The experiences feature is in commit `b696b8f` on `main`. Bump to the first published podspec version that contains it (TBD when iOS team cuts a release). Coordinate with iOS team; may require a temp `:path =>` override during dev.

---

## Phase 5: Android Plugin (`android/src/main/kotlin/com/marfeel/flutter/MarfeelSdkPlugin.kt`)

Same approach. The existing handler dispatches everything via `mainHandler.post { … }` (line 33 / 68) — **but** Android's `Experiences.fetchExperiences` is a `suspend fun` (`Experiences.kt:36`). It cannot run on the main thread directly.

### 5.1 Coroutine scope

Add a `CoroutineScope` field to the plugin class:
```kotlin
private val pluginScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    pluginScope.cancel()
    this.binding = null
}
```

Required imports: `kotlinx.coroutines.*` (already a transitive dep of `com.marfeel.compass:views`, but verify with `./gradlew :marfeel_sdk:dependencies` and add explicitly to `android/build.gradle` if missing).

### 5.2 Recirculation cases

```kotlin
"recirculation.trackEligible" -> {
    val name = call.argument<String>("name")!!
    val links = parseLinks(call.argument<List<Map<String, Any>>>("links"))
    mainHandler.post {
        Recirculation.getInstance().trackEligible(name, links)
        result.success(null)
    }
}

"recirculation.trackImpression" -> { … }
"recirculation.trackImpressionLink" -> {
    val name = call.argument<String>("name")!!
    val link = parseLink(call.argument<Map<String, Any>>("link")!!)
    mainHandler.post {
        Recirculation.getInstance().trackImpression(name, link)
        result.success(null)
    }
}
"recirculation.trackClick" -> { … }
```

Helpers:
```kotlin
private fun parseLink(m: Map<String, Any>): RecirculationLink =
    RecirculationLink(
        url = m["url"] as String,
        position = (m["position"] as Number).toInt()
    )
private fun parseLinks(list: List<Map<String, Any>>?): List<RecirculationLink> =
    list?.map(::parseLink) ?: emptyList()
```

Required imports: `com.marfeel.compass.experiences.Recirculation`, `com.marfeel.compass.experiences.Experiences`, `com.marfeel.compass.experiences.model.*`.

### 5.3 Experiences cases (suspend handling)

```kotlin
"experiences.fetch" -> {
    val filterByType = call.argument<String>("filterByType")?.let { ExperienceType.fromKey(it) }
    val filterByFamily = call.argument<String>("filterByFamily")?.let { ExperienceFamily.fromKey(it) }
    val resolve = call.argument<Boolean>("resolve") ?: false
    val url = call.argument<String>("url")
    pluginScope.launch {
        try {
            val exps = Experiences.getInstance().fetchExperiences(filterByType, filterByFamily, resolve, url)
            cacheLock.withLock {
                experienceCache.clear()
                exps.forEach { experienceCache[it.id] = it }
            }
            val payload = exps.map(::encodeExperience)
            withContext(Dispatchers.Main) { result.success(payload) }
        } catch (e: Exception) {
            Log.e(TAG, "experiences.fetch error: ${e.message}", e)
            withContext(Dispatchers.Main) { result.error("ERROR", e.message, null) }
        }
    }
}
```

`result.success` must be invoked on the Flutter platform thread (main); the IO dispatcher hands off back to main via `withContext(Dispatchers.Main)`.

### 5.4 Track / resolve cases

```kotlin
"experiences.trackImpression" -> {
    val id = call.argument<String>("experienceId")!!
    val name = call.argument<String>("experienceName")!!
    val links = parseLinks(call.argument<List<Map<String, Any>>>("links"))
    val exp = cacheLock.withLock { experienceCache[id] } ?: stubExperience(id, name)
    mainHandler.post {
        Experiences.getInstance().trackImpression(exp, links)
        result.success(null)
    }
}

"experiences.resolve" -> {
    val id = call.argument<String>("experienceId")!!
    val exp = cacheLock.withLock { experienceCache[id] }
    if (exp == null) { result.success(null); return@onMethodCall }
    pluginScope.launch {
        val content = exp.resolve()
        withContext(Dispatchers.Main) { result.success(content) }
    }
}
```

`stubExperience(id, name)` constructs an `Experience(id = id, name = name, type = ExperienceType.UNKNOWN, placement = null, contentUrl = null, contentType = ExperienceContentType.UNKNOWN, features = null, strategy = null, selectors = null, filters = null, rawJson = emptyMap(), family = null)` — used only when the cache misses (e.g., consumer holds a stale reference). `resolve` returns `null` for stubs because there's no content URL.

### 5.5 `encodeExperience` (Android)

```kotlin
private fun encodeExperience(e: Experience): Map<String, Any?> = mapOf(
    "id" to e.id,
    "name" to e.name,
    "type" to e.type.key,
    "family" to e.family?.key,
    "placement" to e.placement,
    "contentUrl" to e.contentUrl,
    "contentType" to e.contentType.key,
    "features" to e.features,
    "strategy" to e.strategy,
    "selectors" to e.selectors?.map { mapOf("selector" to it.selector, "strategy" to it.strategy) },
    "filters" to e.filters?.map { mapOf("key" to it.key, "operator" to it.operator, "values" to it.values) },
    "rawJson" to e.rawJson,
    "resolvedContent" to e.resolvedContent,
)
```

⚠️ `features` and `rawJson` are `Map<String, Any>?`. Same codec-compatibility caveat as iOS. `JSONObject.toMap()` does not exist on Android; if the SDK stores raw `JSONObject` instances, normalise to `Map<String, Any>` before sending. Verify by reading `ExperiencesResponseParser.kt`.

### 5.6 Native dep bump

`android/build.gradle` currently pulls `com.marfeel.compass:views:1.16.6`. Experiences was merged in PR #43 on `experiences-api` branch — not yet released. Bump to whichever version contains the merge once published. Coordinate with Android team; during dev use `mavenLocal()` or a SNAPSHOT.

### 5.7 QA case wiring

Map 1:1 to native methods. `getFrequencyCapCounts` returns `Map<String, Long>` on Android and `[String: Int]` on iOS — Dart side must accept both (`(value as Map).map((k,v) => MapEntry(k as String, (v as num).toInt()))`).

---

## Phase 6: Barrel Export & Method Channel Reuse

```dart
// lib/marfeel_sdk.dart
export 'src/compass_tracking.dart';
export 'src/multimedia_tracking.dart';
export 'src/types.dart';
export 'src/compass_scroll_view.dart';
export 'src/experiences/experiences.dart';
export 'src/experiences/recirculation.dart';
export 'src/experiences/models.dart';
```

No new MethodChannel — reuse `MarfeelSdkChannel.channel` (`com.marfeel.sdk/compass`). Single channel keeps the iOS / Kotlin handlers unified.

---

## Phase 7: Tests (`flutter_test` with mock binary messenger)

Existing tests use `setMockMethodCallHandler` (`test/compass_tracking_test.dart:13`). New tests follow the same pattern.

### 7.1 `test/recirculation_test.dart`

| Test | Asserts |
|---|---|
| `trackEligible` sends correct method + args | `method == 'recirculation.trackEligible'`, `name`, `links` (list of maps with `url`, `position`) |
| `trackImpression` (multi link) | same shape |
| `trackImpressionLink` (single link) | uses `link` key (not `links`), single map |
| `trackClick` | uses `link` key |
| `RecirculationLink.toMap` | preserves `url` and `position` (incl. `position: 255` sentinel value) |

### 7.2 `test/experiences_test.dart`

| Test | Asserts |
|---|---|
| `fetchExperiences` no filters | method, empty filter args |
| `fetchExperiences` with type+family filters | sends `value` strings (`"adManager"`, `"recommenderexperience"`), `resolve=false`, `url=null` |
| `fetchExperiences` returns `[]` when channel returns null | empty list, no exception |
| `fetchExperiences` parses one experience | calls native, decodes via `Experience.fromMap` |
| `addTargeting` | method + key/value |
| `trackImpression(experience:, links:)` | sends `experienceId` + `experienceName` + `links` |
| `trackClose` | sends only `experienceId` |
| `resolveExperience` | mutates `experience.resolvedContent` after future completes |
| `getFrequencyCapCounts` parses Map<String, Int> | accepts both `int` and `int64` shapes (Android sends Long) |
| `getFrequencyCapConfig` parses `Map<String, List<String>>` | nested list parsing |
| `setExperimentAssignment` | method + groupId + variantId |
| QA: `clearFrequencyCaps` / `clearReadEditorials` / `clearExperimentAssignments` | method only |

### 7.3 `test/experiences_models_test.dart`

| Test | Asserts |
|---|---|
| `ExperienceType.fromKey` | known key → enum, unknown → null |
| `ExperienceFamily.fromKey` | known → enum, unknown → `unknown` |
| `ExperienceContentType.fromKey` | same |
| `Experience.fromMap` full payload | every field decoded, `resolvedContent` initially null |
| `Experience.fromMap` minimal payload | only required fields, optionals null, no exception |
| `RecirculationLink.toMap` | round-trips |
| `ExperienceFilter.fromMap` / `ExperienceSelector.fromMap` | decode |

### 7.4 No native-side tests in this repo

Native tests live in their respective SDK repos (already exist on iOS PR #47 and Android `experiences-api`). The Flutter plugin tests verify the Dart ↔ MethodChannel boundary only. Same convention as existing `compass_tracking_test.dart`.

---

## Phase 8: Example App (`example/lib/screens/experiences_screen.dart`)

Add an "Experiences" tab to the existing 3-tab `MainScreen` (`example/lib/main.dart:51`). UI mirrors the iOS Playground spec from `ios_impl_plan.md` Phase 10.

Layout:
- Section: **Targeting** — TextFields for key+value, "Add Targeting" button → `Experiences.addTargeting`
- Section: **Fetch** — TextField for url override, two `DropdownButton<ExperienceType?>` / `<ExperienceFamily?>` (with "All" option), `Switch` for `resolve`, "Fetch Experiences" button → calls `Experiences.fetchExperiences(...)` and stores result in state
- Section: **Results** — `ListView` of fetched experiences, each card shows `id`, `name`, `type.value`, `family?.value`, `contentUrl`, with action chips: "Eligible", "Impression", "Click", "Close", "Resolve" (and a sub-tile showing `resolvedContent` snippet)
- Section: **QA** — Buttons: "Clear Freq Caps", "Show Counts" (calls `getFrequencyCapCounts(selectedExpId)` → SnackBar with map), "Clear Editorials", "Show Editorials", "Clear Experiments", "Show Experiments"

Test value ahead of the SDK team finalising payloads: when `fetchExperiences` returns empty or errors, the screen should show a helpful message rather than break.

---

## Phase 9: Documentation

- **`README.md`** — add a section after the existing "Multimedia Tracking" example with minimal Recirculation + Experiences snippets.
- **`CLAUDE.md`** — append Experiences API description to the Architecture / Dart layer section so future LLM sessions see the new files.
- **`CHANGELOG.md`** — entry: `feat: Experiences and Recirculation tracking APIs`.

---

## Implementation Order

1. **Models & exports** (`lib/src/experiences/models.dart`, update barrel) — pure Dart, unblocks tests
2. **Dart APIs** (`recirculation.dart`, `experiences.dart`) — invokeMethod calls only, no native impl yet
3. **Tests for Dart layer** — green against mock channel before touching native
4. **iOS plugin** — add cases, podspec dep bump (coordinate with iOS team)
5. **Android plugin** — add cases, gradle dep bump (coordinate with Android team)
6. **Manual end-to-end on example app** — both platforms, verify network requests in Charles/Proxyman match wire formats from `ios_impl_plan.md` "Wire Format Parity" table
7. **Example screen + docs**
8. **Release notes + version bump** in `pubspec.yaml`

---

## Native Dependency Versions (open questions)

| Platform | Current | Required for experiences | Action |
|---|---|---|---|
| iOS | `MarfeelSDK-iOS ~> 2.18.7` (CocoaPods) | First release containing iOS commit `b696b8f` (`MF-7571`). Likely `2.19.x` | Wait for release tag, then bump in `ios/marfeel_sdk.podspec`. During dev: `pod 'MarfeelSDK-iOS', :path => '../../MarfeelSDK-iOS'` |
| Android | `com.marfeel.compass:views:1.16.6` | First release containing Android `experiences-api` PR #43 | Wait for merge to `master` + Maven publish. During dev: point gradle to `mavenLocal()` |

Before merging this Flutter plan, open coordination tickets with both SDK teams to confirm release versions.

---

## Risk Notes

- **Codec compatibility for `features` and `rawJson`** — these are `Map<String, Any>` natively. If the response parser leaves nested `JSONObject` (Android) or `NSNumber` (iOS) instances in there, the Flutter `StandardMessageCodec` will throw. Mitigation: native-side normalisation step in `encodeExperience`, plus a round-trip test.
- **`Experience` cache eviction** — using "last fetch wins" means consumers holding `Experience` references from a prior fetch will silently fall back to stub semantics for `trackImpression`/`trackClose`. Acceptable because freq-cap tracking only needs `id`, but **document** in the Dart class doc-comment.
- **Resolve timeout** — iOS already enforces 10s. Android `coroutineScope` will block forever on a hung HTTP call. The Flutter `Future` will resolve only after native does. Document that consumers calling `fetchExperiences(resolve: true)` should consider their own timeout, or better, prefer `fetchExperiences(resolve: false)` + per-experience `resolveExperience` (which can be cancelled via `Future.timeout`).
- **iOS / Android wire-format divergence on impression `name`** (see "Behaviour parity gap" above). Not Flutter's job to paper over, but track in the SDK team backlog.
- **Method-channel thread on Android** — `result.success` must be called on the platform thread. The existing plugin uses `mainHandler.post`; suspend cases use `withContext(Dispatchers.Main) { result.success(...) }`. Verify with the Flutter team's docs on `MethodChannel` invocation thread guarantees if any test flakes.
