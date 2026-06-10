# Perbaikan Upload Gambar - Versi 2 (Dengan Fallback)

## Masalah yang Terjadi

Gambar tidak bisa diupload karena error **SocketException: Connection reset by peer** dari ImgBB API. Ini terjadi karena:
1. API key ImgBB mungkin sudah tidak valid atau expired
2. Rate limit ImgBB terlampaui (terlalu banyak request)
3. ImgBB server sedang down atau tidak stabil
4. Masalah koneksi internet

## Solusi yang Diterapkan

### 🔄 Sistem Fallback Otomatis

Saya telah membuat sistem upload gambar dengan **fallback otomatis**:
1. **Coba ImgBB dulu** (gratis, cepat, tidak pakai quota Firebase)
2. **Jika ImgBB gagal → otomatis pakai Firebase Storage** (reliable, terintegrasi dengan Firebase)

### 📁 File Baru yang Dibuat

1. **`lib/services/firebase_storage_service.dart`**
   - Service untuk upload ke Firebase Storage
   - Menggunakan Firebase Authentication untuk keamanan
   - Menyimpan gambar dengan struktur folder yang rapi

2. **`lib/services/image_upload_service.dart`**
   - Service wrapper yang menggabungkan ImgBB dan Firebase Storage
   - Otomatis fallback jika ImgBB gagal
   - Logging lengkap untuk debugging

### 🔧 Perubahan pada ImgBB Service

**`lib/services/imgbb_service.dart`** - Ditambahkan:
- ✅ Retry logic (3x percobaan)
- ✅ Timeout 30 detik
- ✅ Better error handling untuk SocketException
- ✅ Retry otomatis untuk server errors (5xx) dan rate limit (429)
- ✅ Delay antara retry untuk menghindari rate limit

### 📝 File yang Diupdate

Semua file yang menggunakan upload gambar sudah diupdate untuk menggunakan `ImageUploadService`:

1. ✅ `lib/screens/user_profile_screen.dart` - Foto profil & foto hewan
2. ✅ `lib/screens/doctor_profile_screen.dart` - Foto profil dokter
3. ✅ `lib/screens/clinic_profile_screen.dart` - Foto profil klinik
4. ✅ `lib/screens/add_article_screen.dart` - Gambar artikel
5. ✅ `lib/screens/add_review_screen.dart` - Foto review
6. ✅ `lib/screens/chat_screen.dart` - Gambar chat
7. ✅ `lib/screens/user_booking_history_screen.dart` - Foto review booking

### 📦 Dependency Baru

Ditambahkan ke `pubspec.yaml`:
```yaml
firebase_storage: ^11.6.0
```

## Cara Kerja Sistem Fallback

```
User Upload Gambar
       ↓
Coba ImgBB (3x retry)
       ↓
   Berhasil? ──→ YES ──→ Return URL ImgBB ✅
       ↓
      NO
       ↓
Coba Firebase Storage
       ↓
   Berhasil? ──→ YES ──→ Return URL Firebase ✅
       ↓
      NO
       ↓
Show Error Message ❌
```

## Struktur Folder di Firebase Storage

Gambar akan disimpan dengan struktur:
```
/profile_pics/
  - {userId}_{timestamp}.jpg
/pet_pics/
  - {userId}_{timestamp}.jpg
/articles/
  - {userId}_{timestamp}.jpg
/reviews/
  - {userId}_{timestamp}.jpg
/chat_images/
  - {userId}_{timestamp}.jpg
```

## Cara Testing

### 1. Test Upload Foto Profil
1. Buka Profile → Tap kamera
2. Pilih gambar
3. **Cek console log**:
   ```
   Attempting upload via ImgBB...
   ImgBB: Uploading image (X bytes), attempt 1
   ```
   - Jika ImgBB berhasil: `✅ Upload successful via ImgBB`
   - Jika ImgBB gagal: `⚠️ ImgBB upload failed` → `Falling back to Firebase Storage...` → `✅ Upload successful via Firebase Storage`

### 2. Test Upload Foto Hewan
1. Profile → Tambah/Edit hewan
2. Upload foto
3. Cek console log untuk melihat proses upload

### 3. Test Upload Gambar Chat
1. Buka chat dengan dokter
2. Tap attachment → pilih gambar
3. Kirim
4. Cek console log

### 4. Test Upload Foto Review
1. Buka detail klinik/dokter
2. Tulis ulasan dengan foto
3. Submit
4. Cek console log

## Keuntungan Sistem Baru

### ✅ Reliability
- Jika satu service gagal, otomatis pakai yang lain
- Tidak ada downtime karena masalah satu service

### ✅ Performance
- ImgBB lebih cepat (jika available)
- Firebase Storage sebagai backup yang reliable

### ✅ Cost Efficiency
- ImgBB gratis (tidak pakai quota Firebase)
- Firebase Storage hanya dipakai jika ImgBB gagal

### ✅ Better Error Handling
- Retry otomatis untuk error sementara
- Error message yang jelas untuk user
- Logging lengkap untuk debugging

## Troubleshooting

### Jika Masih Gagal Upload:

1. **Cek Console Log**
   - Lihat apakah ImgBB dicoba
   - Lihat error message dari ImgBB
   - Lihat apakah fallback ke Firebase Storage
   - Lihat error message dari Firebase Storage (jika ada)

2. **Cek Firebase Storage Rules**
   - Buka Firebase Console → Storage → Rules
   - Pastikan rules mengizinkan write untuk authenticated users:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }
   ```

3. **Cek Internet Connection**
   - Pastikan device/emulator terkoneksi internet
   - Test dengan browser apakah bisa akses internet

4. **Cek Firebase Authentication**
   - Pastikan user sudah login
   - Firebase Storage memerlukan user authenticated

## Console Log Examples

### ✅ Berhasil via ImgBB:
```
Attempting upload via ImgBB...
ImgBB: Uploading image (245678 bytes), attempt 1
ImgBB Response Status: 200
ImgBB Image URL: https://i.ibb.co/xxxxx/image.jpg
✅ Upload successful via ImgBB
```

### ✅ Berhasil via Firebase Storage (setelah ImgBB gagal):
```
Attempting upload via ImgBB...
ImgBB: Uploading image (245678 bytes), attempt 1
ImgBB ClientException: SocketException: Connection reset by peer
Retrying upload after 1 seconds...
ImgBB: Uploading image (245678 bytes), attempt 2
ImgBB ClientException: SocketException: Connection reset by peer
Retrying upload after 2 seconds...
ImgBB: Uploading image (245678 bytes), attempt 3
ImgBB ClientException: SocketException: Connection reset by peer
⚠️ ImgBB upload failed: Exception: Koneksi gagal...
Falling back to Firebase Storage...
Firebase Storage: Uploading to profile_pics/user123_1234567890.jpg (245678 bytes)
Firebase Storage URL: https://firebasestorage.googleapis.com/...
✅ Upload successful via Firebase Storage
```

### ❌ Gagal Total:
```
Attempting upload via ImgBB...
ImgBB: Uploading image (245678 bytes), attempt 1
ImgBB Upload Error: ...
⚠️ ImgBB upload failed: ...
Falling back to Firebase Storage...
Firebase Storage Error: ...
❌ Firebase Storage upload also failed: ...
```

## Konfigurasi Firebase Storage (Jika Belum)

Jika Firebase Storage belum dikonfigurasi:

1. **Buka Firebase Console**
   - https://console.firebase.google.com
   - Pilih project Vetra

2. **Enable Storage**
   - Klik "Storage" di menu kiri
   - Klik "Get Started"
   - Pilih lokasi server (pilih yang terdekat, misal: asia-southeast1)
   - Klik "Done"

3. **Set Storage Rules**
   - Tab "Rules"
   - Paste rules di atas
   - Klik "Publish"

4. **Test Upload**
   - Coba upload gambar dari aplikasi
   - Cek di Firebase Console → Storage → Files
   - Gambar harus muncul di folder yang sesuai

## Next Steps

Sistem upload gambar sekarang sudah sangat reliable dengan fallback otomatis. Jika masih ada masalah:
1. Cek console log untuk error details
2. Pastikan Firebase Storage sudah dikonfigurasi
3. Pastikan internet connection stabil
4. Screenshot error dan console log untuk analisis lebih lanjut
