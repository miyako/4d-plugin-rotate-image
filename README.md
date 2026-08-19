![version](https://img.shields.io/badge/version-18%2B-EB8E5F)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-rotate-image)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-rotate-image/total)

# 4d-plugin-rotate-image

Rotates an encoded image (the raw bytes of a JPEG, PNG, etc. — not a 4D `Picture` variable's decoded pixels) by a fixed multiple of 90°, without the cost of an affine transform. Internally it calls OpenCV's `cv::rotate`, decodes the source with `cv::imdecode`, and re-encodes the result with `cv::imencode`. The result is returned as a 4D `Object` containing a rotated `Picture`.

The plugin exists to work around a specific 4D limitation: `GET PICTURE METADATA` can *read* a photo's EXIF orientation tag, but 4D has no built-in way to *apply* that correction to a `Picture` you've already loaded with `READ PICTURE FILE`. This plugin performs that correction cheaply, since real-world photo correction only ever needs a 90°/180°/270° turn, not a general-angle affine rotation.

| Command | Returns | Purpose |
|---|---|---|
| [`Rotate image`](#rotate-image) | `Object` | Rotate an encoded image by 0/90/180/270° and re-encode it as a `Picture`. |

**Platforms:** macOS (Intel & Apple Silicon), Windows 64-bit

---

## Requirements & platform notes

- **4D version 18 or later** (per the badge in this plugin's own repository).
- **Parameter 1 is a `BLOB`, not a `Picture` variable.** The plugin reads it with the SDK's blob-handle parameter accessor, so you must supply the *raw encoded file bytes* (e.g. via `DOCUMENT TO BLOB`) — passing a `Picture` variable directly is not the documented calling convention this command's implementation expects.
- **Rotation angle must be exactly `0`, `90`, `180`, or `270`.** Any other value is silently accepted but does nothing: no rotation is applied, no image is returned, and `success` comes back `false` with no further explanation in the result object. See the caveat immediately below before relying on any other value.
- **This repository's own `README.md` documents `ROTATE_90_COUNTERCLOCKWISE` as the value `279`, but the plugin's actual C++ implementation only recognizes `270` for that rotation.** These two sources disagree. This doc uses the value verified directly from the source (`270`, matching `cv::ROTATE_90_COUNTERCLOCKWISE`) — if your project has a 4D constants file defining `ROTATE_90_COUNTERCLOCKWISE`, confirm it's set to `270` before relying on it, since `279` will silently no-op per the point above.
- **The output format string must resolve to a single recognized file extension** (e.g. `.png`, `.jpg`). This plugin normalizes a missing leading `.` for you, but a string with no dot at all, or more than one dot, is rejected (`success: false`) rather than guessed at.
- **On failure, the result object only ever contains the `success` key** (set to `false`). It does not contain a Boolean/error-code breakdown of *why* — see Error handling below for how to distinguish the failure causes described above.

---

## Rotate image

### Syntax

```4d
status:=Rotate image(image; rotate; format)
```

| Parameter | Type | Description |
|---|---|---|
| `image` | BLOB | The raw encoded bytes of the source image (JPEG, PNG, or any format OpenCV's `imdecode` recognizes) — not a decoded `Picture` variable. |
| `rotate` | Longint | Rotation angle in degrees, clockwise. Only `0`, `90`, `180`, and `270` are recognized; any other value silently produces `success: false` with no rotation performed (see the caveat above regarding the README's `279`). |
| `format` | Text | Optional. Output file extension for the re-encoded result, e.g. `.png`, `.jpg`. If omitted or empty, defaults to `.png`. Must resolve to a single recognized extension (leading `.` is added for you if missing) — a string with no dot, or with more than one dot, is rejected. |
| `status` (Result) | Object | See the properties table below. |

**`status` object properties:**

| Property | Type | Description |
|---|---|---|
| `success` | Boolean | `true` if the image was decoded, rotated, and re-encoded successfully. Always present. |
| `image` | Picture | The rotated image, re-encoded in the requested (or default) format. Present only when `success` is `true`. |
| `time` | Real | Elapsed time in seconds for the decode/rotate/encode operation. Present only when `success` is `true`. |

### Description

`Rotate image` decodes the bytes in `image` (via OpenCV's `imdecode`, using whatever codecs are compiled into the plugin's vendored OpenCV — exact supported input formats depend on that build and aren't enumerated in the plugin's own source, so if you need to confirm a specific unusual format is supported, test it directly), applies a fixed 90°-multiple rotation, and re-encodes the result using the extension you supplied in `format`. Rotating by `0` still round-trips the image through the same decode → (no-op) → re-encode → `Picture` pipeline, so it's a legitimate way to normalize an image into a different container format even without an actual rotation.

Because `rotate` and `format` are validated *before* any decoding happens, an unrecognized `format` or an unrecognized `rotate` value both fail cleanly with `success: false` rather than attempting a partial operation. A `rotate` value outside `{0, 90, 180, 270}` and a malformed/corrupt `image` blob are the two most likely real-world causes of `success: false`; the result object doesn't currently distinguish between them, so if you need to tell them apart, validate `rotate` against the known set yourself before calling.

### Example

```4d
var $blob : Blob
var $status : Object

DOCUMENT TO BLOB(File("/RESOURCES/photo.jpg").path; $blob)

$status:=Rotate image($blob; 90; ".jpg")

If ($status.success)
	FORM Picture:=$status.image
Else
	ALERT("Rotation failed")
End if
```

Rotating using the EXIF orientation you already read with `GET PICTURE METADATA`, and normalizing to PNG regardless of the source format:

```4d
var $picture : Picture
var $blob : Blob
var $orientation : Integer
var $status : Object

READ PICTURE FILE(File("/RESOURCES/photo.jpg").path; $picture)
GET PICTURE METADATA($picture; TIFF orientation; $orientation)

DOCUMENT TO BLOB(File("/RESOURCES/photo.jpg").path; $blob)

Case of
	: ($orientation=6)
		$status:=Rotate image($blob; 90; ".png")
	: ($orientation=3)
		$status:=Rotate image($blob; 180; ".png")
	: ($orientation=8)
		$status:=Rotate image($blob; 270; ".png")
	Else
		$status:=Rotate image($blob; 0; ".png")
End case

If ($status.success)
	FORM Picture:=$status.image
End if
```

The exact numeric-to-orientation mapping above (6/3/8) follows the standard EXIF orientation tag convention; confirm it against your own source images' tags rather than assuming it universally, since `GET PICTURE METADATA`'s returned value depends on the tag actually written by the capturing device or app.

---

## Error handling & troubleshooting

- **`success: false` with no other keys present** — one of: the `image` blob wasn't decodable by any codec compiled into the plugin's OpenCV, `rotate` wasn't one of `0`/`90`/`180`/`270`, or `format` didn't resolve to a single recognized extension. The result object doesn't currently separate these causes; check `rotate` and `format` against the constraints above first, since they're the cheapest to rule out.
- **The `279` constant from this project's own `README.md` does not work.** If your calling code defines `ROTATE_90_COUNTERCLOCKWISE` as `279` (matching the README), it will always fall into the "unrecognized rotate value" no-op path described above. Use `270` until this is reconciled at the source.
- **`image`/`time` are absent, not `Null`, on failure.** Don't reference `$status.image` unconditionally — check `$status.success` first, or you'll get a `Null`/undefined-property read rather than a valid `Picture`.
- **This command does not crash or hang on malformed input.** The plugin's exception handling guarantees a `success: false` result is always returned rather than the host waiting indefinitely, even for corrupt image bytes or an unencodable rotation result — you can safely call it in a loop without a watchdog timer for this specific failure mode.

---

## Quick reference

```4d
var $blob : Blob
var $status : Object

DOCUMENT TO BLOB(File("/RESOURCES/photo.jpg").path; $blob)
$status:=Rotate image($blob; 90; ".png")  // 0, 90, 180, 270 only

If ($status.success)
	FORM Picture:=$status.image  // $status.time holds elapsed seconds
End if
```
