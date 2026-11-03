# REVERSE

[Web’de oyna](https://ardaisik99.github.io/reverse/) · [Android deneme APK’sı](https://github.com/ardaisik99/reverse/releases/latest)


**İki yön. Tek çözüm.** Godot 4.7.2 ile yapılmış, Türkçe, mobil odaklı bir matematik bulmaca oyunu. Renkler sıcak krem, lacivert, mercan, adaçayı ve altın tonlarından oluşur. Arayüz vektöreldir; büyük PNG dosyaları veya haricî ağ istekleri kullanmaz.

## Çalıştırma

Godot 4.7.2 ile `project.godot` dosyasını açıp F6/F5 ile çalıştırın. Compatibility/OpenGL renderer kullanılır. Web dışa aktarımı tek iş parçacıklıdır; GitHub Pages üzerinde COOP/COEP başlıkları gerektirmez.

## Nasıl oynanır?

İki sayıya sırayla dokunarak yerlerini değiştirin. İşaretlere dokunarak kullanılabilir işlemler arasında geçin. Soldan sağa ve sağdan sola hesaplanan sonuçlar aynı anda hedeflere eşit olmalıdır. **İşlem önceliği uygulanmaz.** Sağdan sola giderken hem sayıların hem işlemlerin sırası ters çevrilir; çıkarma ve bölmede operand yönü de buna göre değişir. Bölmeler rasyonel sayılarla tam olarak hesaplanır; kayan noktalı yaklaşık eşitlik kullanılmaz.

Örnek: `2 + 3 × 4` soldan `(2 + 3) × 4 = 20`, sağdan `(4 × 3) + 2 = 14` verir.

## Modlar

- **Bölüm:** 72 deterministik bölüm; 1–18 üç, 19–36 dört, 37–54 beş, 55–72 altı sayı. Çıkarma 13., bölme 55. bölümde açılır. Her bulmaca bilinen bir çözümden üretilir ve başlangıcı çözülmüş olamaz. Alternatif çözümler kabul edilir.
- **Günlük:** UTC takvimine göre herkes için aynı dört sayılı bulmaca. En iyi hamle/süre bu cihazda saklanır. Sonuç metni panoya kopyalanabilir. Ortak çevrimiçi liderlik tablosu yoktur.
- **Blitz:** Kesintisiz 60 saniye, her çözümde yeni bulmaca. İpucusuz her üç ardışık çözüm çarpanı artırır (en fazla ×5). Yardım ekranı veya sekme değiştirmek süreyi durdurmaz.
- **1v1 düello:** Aynı cihazı sırayla kullanan iki oyuncu, aynı bulmacalarla üç raunt yarışır. Süresi kısa olan raundu kazanır. İpuçları kapalıdır; diğer oyuncu ekrana bakmamalıdır. Bu sürüm internet üzerinden eşleştirme içermez.

Her takas, işlem değişimi, geri alma, sıfırlama ve ipucu bir hamledir. 3 yıldız için ipucusuz, 90 saniye içinde, sayı adedinin en fazla üç katı hamle gerekir. 2 yıldız için en fazla bir ipucu ve sayı adedinin en fazla altı katı hamle gerekir. Diğer tamamlamalar bir yıldız verir. Bu eşikler **matematiksel minimum hamle iddiası değildir**.

## Kontroller ve kayıt

Dokunma/fare; Tab + Enter ile düğmeler. `1`–`6`: sayı seç; `Z`: geri al; `H`: ipucu; `Esc`: geri. Ses ve azaltılmış hareket ayarları bulunur. Bölüm/günlük süresi odak kaybında durur; Blitz ve düello süresi durmaz. İlerleme `user://reverse_save_v1.json` içinde, webde tarayıcının yerel depolamasında tutulur. Tarayıcı verilerini temizlemek kaydı siler. Hesap veya analitik yoktur.

## Doğrulama

```powershell
godot --headless --path . --script self_test.gd
```

Test; 2880 üretilmiş bulmacada çözüm garantisi, çözülmemiş başlangıç, deterministik üretim, sayı kümesinin korunması; iki yönlü kesin aritmetik, sıfıra bölme; dört sayı boyutundaki arayüz, ipucu ile tamamlama, günlük eşitliği, Blitz süre sınırı, modal klavye odağı ve adil düello geçişini denetler. Test öncesindeki kayıt dosyası test bitiminde aynen geri yüklenir.

## Android / iOS

Kaynak proje mobil dokunmatik girişe ve dikey ekrana hazırdır. Android APK/AAB için Godot Android dışa aktarma şablonları, JDK ve Android SDK; mağaza yayını için imzalama anahtarı gerekir. iOS için macOS, Xcode, Apple Developer hesabı ve imzalama gerekir. Kaynak proje Android/iOS uygulaması oluşturmak için kullanılabilir; web bağlantısı App Store veya Play Store yayını anlamına gelmez.

## Yeniden derleme ve otomatik yayın

`tools/export.ps1 -Godot <Godot-exe-yolu> -Target Web` bulmacaları doğrular ve `build/web` içine yayın sürümünü üretir. Android için `-Target Android` kullanılır; JDK 17, Android SDK ve Godot Android şablonları kurulu olmalıdır. `GODOT_BIN` ortam değişkeni de desteklenir. Android çıktısı ARM64 için debug anahtarıyla imzalanmış **deneme APK’sıdır**; Play Store yayını için release imzası ve AAB ayrıca hazırlanmalıdır. APK gerçek bir telefonda sınanmamıştır.

`.github/workflows/pages.yml`, `main` dalına gönderilen kaynakları Godot 4.7.2 ile yeniden test eder, tek iş parçacıklı Web paketini üretir ve GitHub Pages’e yayınlar. Godot ve dışa aktarma şablonu ilk çalışmada resmi Godot deposundan alınır, sonraki çalışmalarda önbellekten kullanılır. Üretilen dosyalar ve yerel kayıtlar kaynak deposuna alınmaz.

Vektör arayüz, az sayıda Control/draw öğesi ve kısa üretilmiş PCM sesler kullanılır. Bulmaca çözümü kare başına çalışmaz. Büyük doku, video, reklam SDK’sı veya üçüncü taraf ağ bağımlılığı yoktur. Web paketinin asıl boyutunu Godot/WebAssembly çalışma zamanı oluşturur.

Godot motoru [MIT lisansı](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt) ve kendi [üçüncü taraf lisansları](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt) kapsamındadır.
