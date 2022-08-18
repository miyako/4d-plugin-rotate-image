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

## プラグイン

内部的に[OpenCV](https://opencv.org)の`cv::rotate`をコールするだけの簡単なプラグインです。

#### 定数

* ROTATE_90_CLOCKWISE (90)
* ROTATE_180 (180)
* ROTATE_90_COUNTERCLOCKWISE (279)
* ROTATE_0 (0)

```4d
status:=Rotate image(image; rotate; format)
```

#### 例題

フォームを表示すると画像が縦向きに表示されます。Finderでは横向きに表示される写真です。

<img width="721" alt="finder" src="https://user-images.githubusercontent.com/1725068/185327490-af028cf6-9ee2-41f7-b336-2f157d13e62a.png">
<img width="499" alt="ss" src="https://user-images.githubusercontent.com/1725068/185326430-f99191fc-9978-4abe-8ca1-704b074aa9d2.png">

