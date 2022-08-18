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

## 問題点

EXIFタグで向きが設定された画像を[READ PICTURE FILE](https://doc.4d.com/4Dv19/4D/19.1/READ-PICTURE-FILE.301-5652800.ja.html)でピクチャに取り込んだ場合，*orientation*は考慮されず，標準(`0`)の向きで画像が表示されます。これは撮影者が意図した向きではないかもしれません。

前述したようにEXIFタグを確認することはできますが，画像を補正するために回転する方法がありません。

SVGの*transform*で回転させることもできますが，**アフィン変換**による回転になるため，画素数が多い写真の回転はそこそこ時間がかかります。

`90`°または`270`°の回転さえできれば良いことを考えると，もっとシンプルな方法が理想的です。
