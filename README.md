# 4d-plugin-rotate-image
画像のEXIFタグを考慮して写真を回転するには

## 概要

スマートフォンで撮影した写真は，EXIFタグの*orientation*により，`90`°の回転がかけられていることがあります。

**参考**: EXIFタグの検証には[exiftool](https://exiftool.org)が便利です。

向きを調べるには

```
exiftool -Orientation -n image.jpg
```

向きを変えるには

```
exiftool -Orientation=8 -n image.jpg
```

向きは[GET PICTURE METADATA](https://doc.4d.com/4Dv19/4D/19.1/GET-PICTURE-METADATA.301-5652804.ja.html)でGETすることができます。残念ながらSETすることはできません。

```4d	
var $orientation : Integer
GET PICTURE METADATA($image; TIFF orientation; $orientation)
```
